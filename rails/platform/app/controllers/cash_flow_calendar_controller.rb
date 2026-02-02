# frozen_string_literal: true

class CashFlowCalendarController < ApplicationController
  authorize_with :cash_flow
  before_action :authorize_edit!, only: %i[confirm update_entry generate_entries]

  def index
    @current_month = params[:month].present? ? Date.parse("#{params[:month]}-01") : Date.current.beginning_of_month
    @start_date = @current_month.beginning_of_month
    @end_date = @current_month.end_of_month
    @dates = (@start_date..@end_date).to_a

    # Load all entries for the month
    @entries = CashFlowEntry.for_date_range(@start_date..@end_date)
                            .includes(:client, :partner, :project, :source)
                            .order(:expected_date, :category)

    # Group by date for matrix display
    @entries_by_date = @entries.group_by(&:expected_date)

    # Calculate running balance
    @opening_balance = calculate_opening_balance(@start_date)
    @daily_balances = calculate_daily_balances(@dates, @entries_by_date, @opening_balance)

    # Category totals
    @income_total = @entries.income.sum(:expected_amount)
    @expense_total = @entries.expense.sum(:expected_amount)
    @income_by_category = @entries.income.group(:category).sum(:expected_amount)
    @expense_by_category = @entries.expense.group(:category).sum(:expected_amount)
  end

  def show
    @date = Date.parse(params[:date])
    @entries = CashFlowEntry.for_date(@date)
                            .includes(:client, :partner, :project, :source)
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

  private

  def entry_params
    params.require(:cash_flow_entry).permit(
      :expected_date, :expected_amount, :actual_amount, :adjustment_amount, :notes
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
