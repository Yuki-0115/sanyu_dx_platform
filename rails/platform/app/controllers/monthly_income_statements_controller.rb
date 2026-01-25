# frozen_string_literal: true

# 月次損益計算書（第1層：会計形式）
# 売上高 - 売上原価 = 売上総利益 - 販管費 = 営業利益
class MonthlyIncomeStatementsController < ApplicationController
  before_action :set_period

  def show
    start_date = Date.new(@year, @month, 1)
    end_date = start_date.end_of_month

    # === 売上高（出来高ベース）===
    @revenue = calculate_progress_revenue(@year, @month)

    # 参考：請求済み金額（税抜）
    @invoiced_amount = Invoice.where(issued_date: start_date..end_date)
                              .where(status: %w[issued paid])
                              .sum(:amount).to_i

    # 未請求額
    @unbilled_amount = [@revenue - cumulative_invoiced_amount(@year, @month), 0].max

    # 出来高入力済みか
    @progress_entered = ProjectMonthlyProgress.exists_for_month?(@year, @month)

    # === 売上原価（第2層から取得）===
    @cost_of_sales = calculate_cost_of_sales(@year, @month)
    @cost_of_sales_details = build_cost_of_sales_details(@year, @month)

    # === 売上総利益（粗利）===
    @gross_profit = @revenue - @cost_of_sales[:total]
    @gross_profit_rate = @revenue.positive? ? ((@gross_profit.to_d / @revenue) * 100).round(1) : 0

    # === 販売費及び一般管理費 ===
    @admin_expenses = MonthlyAdminExpense.for_month(@year, @month).ordered
    @admin_expenses_by_category = MonthlyAdminExpense.by_category_for_month(@year, @month)
    @admin_expenses_total = MonthlyAdminExpense.total_for_month(@year, @month)

    # === 営業利益 ===
    @operating_profit = @gross_profit - @admin_expenses_total
    @operating_profit_rate = @revenue.positive? ? ((@operating_profit.to_d / @revenue) * 100).round(1) : 0
  end

  private

  def set_period
    @year = params[:year].to_i
    @month = params[:month].to_i

    if @year < 2000 || @month < 1 || @month > 12
      redirect_to monthly_income_statement_path(year: Date.current.year, month: Date.current.month)
    end
  end

  # 売上原価を計算（第2層と同じロジック）
  def calculate_cost_of_sales(year, month)
    start_date = Date.new(year, month, 1)
    end_date = start_date.end_of_month

    # 労務費
    if MonthlySalary.confirmed_for_month?(year, month)
      labor_cost = MonthlySalary.total_for_month(year, month)
    else
      labor_cost = calculate_estimated_labor_cost(year, month)
    end

    # 外注費
    if MonthlyOutsourcingCost.confirmed_for_month?(year, month)
      outsourcing_cost = MonthlyOutsourcingCost.total_for_month(year, month)
    else
      outsourcing_cost = calculate_estimated_outsourcing_cost(year, month)
    end

    # 材料費・経費
    expenses = calculate_expenses(year, month)

    # 固定費（現場）
    fixed_cost = MonthlyFixedCost.total_for_month(year, month)

    {
      labor: labor_cost,
      outsourcing: outsourcing_cost,
      material: expenses[:material],
      expense: expenses[:expense],
      fixed: fixed_cost,
      total: labor_cost + outsourcing_cost + expenses[:material] + expenses[:expense] + fixed_cost
    }
  end

  def build_cost_of_sales_details(year, month)
    {
      labor_confirmed: MonthlySalary.confirmed_for_month?(year, month),
      outsourcing_confirmed: MonthlyOutsourcingCost.confirmed_for_month?(year, month),
      material_confirmed: MonthlyCostConfirmation.material_confirmed?(year, month),
      expense_confirmed: MonthlyCostConfirmation.expense_confirmed?(year, month)
    }
  end

  def calculate_estimated_labor_cost(year, month)
    start_date = Date.new(year, month, 1)
    end_date = start_date.end_of_month

    total = 0
    DailyReport.where(report_date: start_date..end_date)
               .where(status: %w[confirmed revised])
               .includes(:project)
               .find_each do |report|
      next unless report.project

      regular_days = report.attendances.joins(:employee)
                           .where(employees: { employment_type: "regular" })
                           .sum("CASE attendance_type WHEN 'full' THEN 1 WHEN 'half' THEN 0.5 ELSE 0 END").to_d
      total += (report.project.regular_labor_unit_price * regular_days).round(0)
    end
    total
  end

  def calculate_estimated_outsourcing_cost(year, month)
    start_date = Date.new(year, month, 1)
    end_date = start_date.end_of_month

    total = 0
    DailyReport.where(report_date: start_date..end_date)
               .where(status: %w[confirmed revised])
               .includes(:project)
               .find_each do |report|
      next unless report.project

      # 外注費（人工）
      outsourcing_days = report.outsourcing_entries
                               .where(billing_type: "man_days")
                               .sum("CASE attendance_type WHEN 'full' THEN headcount WHEN 'half' THEN headcount * 0.5 ELSE 0 END").to_d
      total += (report.project.outsourcing_unit_price * outsourcing_days).round(0)

      # 外注費（請負）
      total += report.outsourcing_entries.where(billing_type: "contract").sum(:contract_amount).to_i
    end
    total
  end

  def calculate_expenses(year, month)
    start_date = Date.new(year, month, 1)
    end_date = start_date.end_of_month

    expenses = Expense.joins(:daily_report)
                      .where(daily_reports: { report_date: start_date..end_date, status: %w[confirmed revised] })
                      .where(status: "approved")
                      .group(:category)
                      .sum(:amount)

    {
      material: (expenses["material"] || 0).to_i,
      expense: expenses.except("material").values.sum.to_i
    }
  end

  # 出来高ベースの売上高を計算（当月分）
  def calculate_progress_revenue(year, month)
    # 当月の出来高
    current_progresses = ProjectMonthlyProgress.for_month(year, month).includes(:project)

    # 出来高が入力されていない場合は請求ベースにフォールバック
    if current_progresses.empty?
      start_date = Date.new(year, month, 1)
      end_date = start_date.end_of_month
      return Invoice.where(issued_date: start_date..end_date)
                    .where(status: %w[issued paid])
                    .sum(:amount).to_i
    end

    # 当月出来高（累計 - 前月累計）の合計
    total = 0
    prev_date = Date.new(year, month, 1).prev_month
    prev_progresses = ProjectMonthlyProgress.for_month(prev_date.year, prev_date.month)
                                            .index_by(&:project_id)

    current_progresses.each do |progress|
      prev_amount = prev_progresses[progress.project_id]&.progress_amount || 0
      monthly_amount = progress.progress_amount - prev_amount
      total += monthly_amount if monthly_amount.positive?
    end

    total.to_i
  end

  # 累計請求済み金額（税抜）
  def cumulative_invoiced_amount(year, month)
    end_date = Date.new(year, month, 1).end_of_month
    Invoice.where("issued_date <= ?", end_date)
           .where(status: %w[issued paid])
           .sum(:amount).to_i
  end
end
