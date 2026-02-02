# frozen_string_literal: true

module Accounting
  class ReimbursementsController < ApplicationController
    before_action :authorize_accounting_access

    # 個人別未精算経費一覧
    def index
      # 立替払い（現金）で未精算の経費を個人別に集計
      @unreimbursed_by_employee = Expense
        .where(payment_method: %w[advance cash])
        .where(reimbursement_required: true, reimbursed: false)
        .includes(:payer, :project, :daily_report)
        .group_by(&:payer)
        .transform_values { |expenses| expenses.sum(&:amount) }
        .sort_by { |_emp, amount| -amount }

      # 精算待ちの経費一覧（直近）
      @pending_expenses = Expense
        .where(payment_method: %w[advance cash])
        .where(reimbursement_required: true, reimbursed: false)
        .includes(:payer, :project, :daily_report)
        .order(created_at: :desc)
        .limit(100)

      # 精算済み（今月）
      @reimbursed_this_month = Expense
        .where(payment_method: %w[advance cash])
        .where(reimbursed: true)
        .where(reimbursed_at: Time.current.beginning_of_month..Time.current.end_of_month)
        .sum(:amount)
    end

    # 従業員別の詳細
    def show
      @employee = Employee.find(params[:id])
      @pending_expenses = Expense
        .where(payer: @employee)
        .where(payment_method: %w[advance cash])
        .where(reimbursement_required: true, reimbursed: false)
        .includes(:project, :daily_report)
        .order(created_at: :desc)

      @reimbursed_expenses = Expense
        .where(payer: @employee)
        .where(reimbursed: true)
        .includes(:project, :daily_report)
        .order(reimbursed_at: :desc)
        .limit(20)

      @total_pending = @pending_expenses.sum(&:amount)
    end

    # 精算処理（個別）
    def reimburse
      @expense = Expense.find(params[:id])

      if @expense.update(reimbursed: true, reimbursed_at: Time.current)
        redirect_back fallback_location: accounting_reimbursements_path,
                      notice: "精算済みにしました（#{@expense.payer&.name}: ¥#{@expense.amount.to_i.to_fs(:delimited)}）"
      else
        redirect_back fallback_location: accounting_reimbursements_path,
                      alert: "精算処理に失敗しました"
      end
    end

    # 一括精算処理
    def bulk_reimburse
      employee = Employee.find(params[:employee_id])
      expenses = Expense
        .where(payer: employee)
        .where(payment_method: %w[advance cash])
        .where(reimbursement_required: true, reimbursed: false)

      count = expenses.count
      total = expenses.sum(:amount)

      expenses.update_all(reimbursed: true, reimbursed_at: Time.current)

      redirect_to accounting_reimbursements_path,
                  notice: "#{employee.name}の立替経費#{count}件（¥#{total.to_i.to_fs(:delimited)}）を精算済みにしました"
    end

    # 精算済み一覧
    def reimbursed
      @year = (params[:year] || Date.current.year).to_i
      @month = (params[:month] || Date.current.month).to_i
      start_date = Date.new(@year, @month, 1)
      end_date = start_date.end_of_month

      @expenses = Expense
        .where(reimbursed: true)
        .where(reimbursed_at: start_date.beginning_of_day..end_date.end_of_day)
        .includes(:payer, :project, :daily_report)
        .order(reimbursed_at: :desc)

      # 従業員フィルター
      if params[:employee_id].present?
        @expenses = @expenses.where(payer_id: params[:employee_id])
        @selected_employee = Employee.find_by(id: params[:employee_id])
      end

      @total_amount = @expenses.sum(:amount)
      @expenses_by_employee = @expenses.group_by(&:payer)
        .transform_values { |exps| exps.sum(&:amount) }
        .sort_by { |_, amount| -amount }

      @employees_with_reimbursements = Employee
        .joins(:expenses_as_payer)
        .where(expenses: { reimbursed: true })
        .distinct
        .order(:name)
    end

    private

    def authorize_accounting_access
      authorize_feature!(:accounting)
    end
  end
end
