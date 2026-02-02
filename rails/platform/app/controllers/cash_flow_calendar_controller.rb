# frozen_string_literal: true

class CashFlowCalendarController < ApplicationController
  authorize_with :cash_flow
  before_action :authorize_edit!, only: %i[confirm update_entry generate_entries create_entry destroy_entry]

  def index
    @current_month = params[:month].present? ? Date.parse("#{params[:month]}-01") : Date.current.beginning_of_month
    @start_date = @current_month.beginning_of_month
    @end_date = @current_month.end_of_month
    @dates = (@start_date..@end_date).to_a

    # Load all entries for the month
    # Note: :source is polymorphic and cannot be eagerly loaded
    @entries = CashFlowEntry.for_date_range(@start_date..@end_date)
                            .includes(:client, :partner, :project)
                            .order(:expected_date, :category)

    # Group by date for matrix display
    @entries_by_date = @entries.group_by(&:expected_date)

    # Calculate running balance
    @opening_balance = calculate_opening_balance(@start_date)
    @daily_balances = calculate_daily_balances(@dates, @entries_by_date, @opening_balance)

    # Category totals (use fresh query without includes to avoid join issues)
    base_query = CashFlowEntry.for_date_range(@start_date..@end_date)
    @income_total = base_query.income.sum(:expected_amount)
    @expense_total = base_query.expense.sum(:expected_amount)
    @income_by_category = base_query.income.group(:category).sum(:expected_amount)
    @expense_by_category = base_query.expense.group(:category).sum(:expected_amount)

    # 会社休日（祝日含む）を取得
    @holidays = CompanyHoliday.where(calendar_type: "office")
                              .for_date_range(@start_date..@end_date)
                              .index_by(&:holiday_date)
  end

  def show
    @date = Date.parse(params[:date])
    # Note: :source is polymorphic and cannot be eagerly loaded
    @entries = CashFlowEntry.for_date(@date)
                            .includes(:client, :partner, :project)
                            .order(:entry_type, :category)

    @income_entries = @entries.income
    @expense_entries = @entries.expense
    @income_total = @income_entries.sum(&:expected_amount)
    @expense_total = @expense_entries.sum(&:expected_amount)
  end

  def confirm
    @entry = CashFlowEntry.find(params[:id])
    @entry.confirm!(
      current_employee,
      amount: params[:actual_amount].present? ? params[:actual_amount].to_d : nil,
      date: params[:expected_date].present? ? Date.parse(params[:expected_date]) : nil,
      notes: params[:notes]
    )
    respond_to do |format|
      format.html { redirect_back fallback_location: cash_flow_calendar_path, notice: "確認済みにしました" }
      format.turbo_stream
    end
  end

  def update_entry
    @entry = CashFlowEntry.find(params[:id])
    if @entry.update(entry_params.merge(manual_override: true, override_reason: params[:reason]))
      redirect_back fallback_location: cash_flow_calendar_path, notice: "更新しました"
    else
      redirect_back fallback_location: cash_flow_calendar_path, alert: "更新に失敗しました"
    end
  end

  # Generate entries for a month (from invoices, fixed expenses, etc.)
  def generate_entries
    year = params[:year]&.to_i || Date.current.year
    month = params[:month]&.to_i || Date.current.month

    CashFlowEntryGenerator.new(year, month).generate_all

    redirect_to cash_flow_calendar_path(month: "#{year}-#{month.to_s.rjust(2, '0')}"),
                notice: "#{year}年#{month}月の資金繰りデータを生成しました"
  end

  # 手動エントリ作成
  def create_entry
    @entry = CashFlowEntry.new(new_entry_params)
    @entry.base_date = @entry.expected_date

    if @entry.save
      redirect_to cash_flow_date_path(date: @entry.expected_date), notice: "登録しました"
    else
      redirect_back fallback_location: cash_flow_calendar_path, alert: "登録に失敗しました: #{@entry.errors.full_messages.join(', ')}"
    end
  end

  # エントリ削除（手動作成のみ）
  def destroy_entry
    @entry = CashFlowEntry.find(params[:id])

    # 自動生成されたエントリは削除不可
    if @entry.source.present?
      redirect_back fallback_location: cash_flow_calendar_path, alert: "自動生成されたエントリは削除できません"
      return
    end

    date = @entry.expected_date
    @entry.destroy
    redirect_to cash_flow_date_path(date: date), notice: "削除しました"
  end

  private

  def entry_params
    params.require(:cash_flow_entry).permit(
      :expected_date, :expected_amount, :actual_amount, :adjustment_amount, :notes
    )
  end

  def new_entry_params
    params.require(:cash_flow_entry).permit(
      :entry_type, :category, :expected_date, :expected_amount, :notes, :subcategory,
      :client_id, :partner_id, :project_id, :status
    )
  end

  def calculate_opening_balance(date)
    # Get completed entries before this month
    income = CashFlowEntry.income.completed.where("actual_date < ?", date).sum(:actual_amount)
    expense = CashFlowEntry.expense.completed.where("actual_date < ?", date).sum(:actual_amount)
    income - expense
  end

  def calculate_daily_balances(dates, entries_by_date, opening_balance)
    running = opening_balance
    dates.map do |date|
      day_entries = entries_by_date[date] || []
      day_income = day_entries.select(&:income?).sum { |e| e.net_amount.to_d }
      day_expense = day_entries.select(&:expense?).sum { |e| e.net_amount.to_d }
      running = running + day_income - day_expense
      { date: date, income: day_income, expense: day_expense, balance: running }
    end
  end

  def authorize_edit!
    return if current_employee.can_edit?(:cash_flow)

    redirect_to cash_flow_calendar_path, alert: "編集権限がありません"
  end
end
