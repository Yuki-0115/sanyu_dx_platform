# frozen_string_literal: true

class ExpenseReportsController < ApplicationController
  before_action :set_expense, only: %i[show edit update destroy]

  # 自分の経費報告一覧
  def index
    @expenses = Expense.includes(:project, :supplier)
                       .where(payer: current_employee)
                       .where(daily_report_id: nil)
                       .order(created_at: :desc)

    @pending_count = @expenses.pending.count
    @approved_count = @expenses.approved.count
  end

  # 経費報告詳細
  def show
  end

  # 新規経費報告
  def new
    @expense = Expense.new(
      expense_type: params[:expense_type] || "sales",
      payer: current_employee
    )
    load_form_data
  end

  # 経費報告作成
  def create
    @expense = Expense.new(expense_params)
    @expense.payer = current_employee

    # 現場経費は日報から入力するため、ここでは営業・管理のみ
    expense_type = params[:expense][:expense_type]
    @expense.expense_type = %w[sales admin].include?(expense_type) ? expense_type : "sales"

    # 立替払いは精算対象フラグを立てる
    @expense.reimbursement_required = @expense.advance_payment?

    if @expense.save
      redirect_to expense_reports_path, notice: "経費を報告しました"
    else
      load_form_data
      render :new, status: :unprocessable_entity
    end
  end

  # 経費報告編集
  def edit
    load_form_data
  end

  # 経費報告更新
  def update
    if @expense.update(expense_params)
      redirect_to expense_reports_path, notice: "経費を更新しました"
    else
      load_form_data
      render :edit, status: :unprocessable_entity
    end
  end

  # 経費報告削除（未承認のみ）
  def destroy
    if @expense.pending?
      @expense.destroy
      redirect_to expense_reports_path, notice: "経費を削除しました"
    else
      redirect_to expense_reports_path, alert: "承認済みの経費は削除できません"
    end
  end

  private

  def set_expense
    @expense = Expense.find(params[:id])
  end

  def load_form_data
    @projects = Project.active.order(:name)
    @partners = Partner.order(:name)
  end

  def expense_params
    params.require(:expense).permit(
      :project_id, :supplier_id, :category, :description,
      :amount, :quantity, :unit, :payment_method,
      :payee_name, :receipt, :voucher
    )
  end
end
