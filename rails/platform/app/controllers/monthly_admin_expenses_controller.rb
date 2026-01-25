# frozen_string_literal: true

class MonthlyAdminExpensesController < ApplicationController
  before_action :set_period
  before_action :set_admin_expense, only: [:edit, :update, :destroy]

  def index
    @admin_expenses = MonthlyAdminExpense.for_month(@year, @month).ordered
    @grouped_expenses = @admin_expenses.group_by(&:category)
    @total = MonthlyAdminExpense.total_for_month(@year, @month)
    @by_category = MonthlyAdminExpense.by_category_for_month(@year, @month)
  end

  def new
    @admin_expense = MonthlyAdminExpense.new(year: @year, month: @month)
  end

  def create
    @admin_expense = MonthlyAdminExpense.new(admin_expense_params)
    @admin_expense.year = @year
    @admin_expense.month = @month
    @admin_expense.amount = normalize_number(params[:monthly_admin_expense][:amount])

    # カスタムカテゴリの処理（選択がない場合のみ）
    if @admin_expense.category.blank? && params[:custom_category].present?
      @admin_expense.category = params[:custom_category]
    end

    if @admin_expense.save
      redirect_to monthly_admin_expenses_path(year: @year, month: @month), notice: "販管費を追加しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    update_params = admin_expense_params.merge(
      amount: normalize_number(params[:monthly_admin_expense][:amount])
    )

    # カスタムカテゴリの処理（選択がない場合のみ）
    if update_params[:category].blank? && params[:custom_category].present?
      update_params = update_params.merge(category: params[:custom_category])
    end

    if @admin_expense.update(update_params)
      redirect_to monthly_admin_expenses_path(year: @year, month: @month), notice: "販管費を更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @admin_expense.destroy
    redirect_to monthly_admin_expenses_path(year: @year, month: @month), notice: "販管費を削除しました"
  end

  def copy_from_previous
    if MonthlyAdminExpense.exists_for_month?(@year, @month)
      redirect_to monthly_admin_expenses_path(year: @year, month: @month),
                  alert: "この月には既にデータがあります。コピーする場合は先に削除してください。"
      return
    end

    copied_count = MonthlyAdminExpense.copy_from_previous_month(@year, @month)
    if copied_count > 0
      redirect_to monthly_admin_expenses_path(year: @year, month: @month),
                  notice: "前月の販管費を#{copied_count}件コピーしました"
    else
      redirect_to monthly_admin_expenses_path(year: @year, month: @month),
                  alert: "前月のデータがありません"
    end
  rescue => e
    redirect_to monthly_admin_expenses_path(year: @year, month: @month),
                alert: "コピーに失敗しました: #{e.message}"
  end

  # テンプレートから一括作成
  def bulk_create
    created_count = 0
    errors = []

    params[:expenses]&.each do |_, expense_data|
      amount = normalize_number(expense_data[:amount])
      next if amount <= 0
      next if expense_data[:name].blank?

      expense = MonthlyAdminExpense.new(
        year: @year,
        month: @month,
        category: expense_data[:category],
        name: expense_data[:name],
        amount: amount,
        description: expense_data[:description]
      )

      if expense.save
        created_count += 1
      else
        errors << "#{expense_data[:name]}: #{expense.errors.full_messages.join(', ')}"
      end
    end

    if errors.any?
      redirect_to monthly_admin_expenses_path(year: @year, month: @month),
                  alert: "一部のデータの保存に失敗しました: #{errors.join('; ')}"
    elsif created_count > 0
      redirect_to monthly_admin_expenses_path(year: @year, month: @month),
                  notice: "#{created_count}件の販管費を登録しました"
    else
      redirect_to monthly_admin_expenses_path(year: @year, month: @month),
                  alert: "金額が入力された項目がありません"
    end
  end

  private

  def set_period
    @year = params[:year].to_i
    @month = params[:month].to_i

    if @year < 2000 || @month < 1 || @month > 12
      redirect_to monthly_admin_expenses_path(year: Date.current.year, month: Date.current.month)
    end
  end

  def set_admin_expense
    @admin_expense = MonthlyAdminExpense.find(params[:id])
  end

  def admin_expense_params
    params.require(:monthly_admin_expense).permit(:name, :category, :amount, :description)
  end
end
