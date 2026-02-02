# frozen_string_literal: true

class CashFlowEntryGenerator
  def initialize(year, month)
    @year = year
    @month = month
    @start_date = Date.new(year, month, 1)
    @end_date = @start_date.end_of_month
  end

  def generate_all
    ActiveRecord::Base.transaction do
      generate_from_invoices
      generate_outsourcing_payments
      generate_fixed_expenses
    end
  end

  def generate_from_invoices
    Invoice.where(status: %w[issued waiting])
           .includes(project: :client)
           .find_each do |invoice|
      next if CashFlowEntry.exists?(source: invoice)

      client = invoice.project&.client
      term = invoice.payment_term || client&.default_payment_term
      # 入金は土日祝日の翌営業日に調整
      expected_date = term&.calculate_payment_date(invoice.issued_date || Date.current, adjust_for: :income) ||
                      PaymentTerm.next_business_day(invoice.due_date || (invoice.issued_date || Date.current) + 1.month)

      CashFlowEntry.create!(
        entry_type: "income",
        category: "receivable",
        source: invoice,
        client: client,
        project: invoice.project,
        base_date: invoice.issued_date || Date.current,
        expected_date: expected_date,
        expected_amount: invoice.total_amount
      )
    end
  end

  def generate_outsourcing_payments
    Partner.includes(:payment_terms).find_each do |partner|
      term = partner.default_payment_term
      next unless term

      # Calculate payment date for outsourcing costs incurred this month
      # 外注費は土日祝日の前営業日に調整
      expected_date = term.calculate_payment_date(@end_date, adjust_for: :expense)

      # Get total outsourcing costs for this partner this month
      # from confirmed monthly_outsourcing_costs or daily_report outsourcing_entries
      amount = calculate_outsourcing_amount(partner)

      next if amount.zero?

      entry = CashFlowEntry.find_or_initialize_by(
        entry_type: "expense",
        category: "outsourcing",
        partner: partner,
        base_date: @end_date
      )

      entry.update!(
        expected_date: expected_date,
        expected_amount: amount
      ) unless entry.manual_override?
    end
  end

  def generate_fixed_expenses
    FixedExpenseSchedule.active.find_each do |schedule|
      # 固定費は土日祝日の前営業日に調整
      payment_date = schedule.payment_date_for_month(@year, @month, adjust_for_holiday: true)

      entry = CashFlowEntry.find_or_initialize_by(
        entry_type: "expense",
        category: schedule.category,
        source: schedule,
        base_date: @start_date
      )

      # Don't override if manually edited
      unless entry.manual_override?
        entry.update!(
          expected_date: payment_date,
          expected_amount: schedule.amount || 0,
          subcategory: schedule.name
        )
      end
    end
  end

  private

  def calculate_outsourcing_amount(partner)
    # Try to get from confirmed monthly_outsourcing_cost first
    if defined?(MonthlyOutsourcingCost)
      cost = MonthlyOutsourcingCost.find_by(partner: partner, year: @year, month: @month)
      return cost.confirmed_amount if cost&.confirmed_amount.present?
    end

    # Fall back to calculating from outsourcing_entries in daily_reports
    OutsourcingEntry.joins(daily_report: :project)
                    .where(partner: partner)
                    .where(daily_reports: { report_date: @start_date..@end_date })
                    .sum(:amount)
  rescue StandardError
    0
  end
end
