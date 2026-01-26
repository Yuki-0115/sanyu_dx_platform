# frozen_string_literal: true

module Accounting
  class ExpensesController < ApplicationController
    before_action :set_expense, only: %i[show process_expense]

    # 経費処理ダッシュボード（タブ切り替え）
    def index
      @tab = params[:tab] || "cash"
      @current_date = Date.current

      case @tab
      when "invoices"
        load_invoice_expenses
      when "card"
        load_card_expenses
      else
        load_cash_expenses
      end
    end

    # 処理済み経費一覧
    def processed
      @expenses = Expense.includes(:project, :daily_report, :payer, :processed_by, :supplier)
                         .accounting_processed
                         .order(processed_at: :desc)

      if params[:year].present? && params[:month].present?
        start_date = Date.new(params[:year].to_i, params[:month].to_i, 1)
        end_date = start_date.end_of_month
        @expenses = @expenses.where(processed_at: start_date.beginning_of_day..end_date.end_of_day)
      end

      @total_amount = @expenses.sum(:amount)
    end

    # 経費詳細（レシート確認）
    def show
    end

    # 経理処理実行
    def process_expense
      if @expense.process_accounting!(current_employee, expense_params)
        redirect_to accounting_expenses_path(tab: determine_tab(@expense)),
                    notice: "経費を処理しました"
      else
        render :show, status: :unprocessable_entity
      end
    end

    # 一括処理
    def bulk_process
      expense_ids = params[:expense_ids] || []
      processed_count = 0

      Expense.where(id: expense_ids).ready_for_accounting.find_each do |expense|
        expense.process_accounting!(current_employee, {})
        processed_count += 1
      end

      redirect_to accounting_expenses_path(tab: params[:tab]),
                  notice: "#{processed_count}件の経費を処理しました"
    end

    # 請求書突合確認（仕入先単位）
    def confirm_supplier
      supplier = Partner.find(params[:supplier_id])
      year = params[:year].to_i
      month = params[:month].to_i
      start_date = Date.new(year, month, 1)
      end_date = start_date.end_of_month

      expenses = Expense.ready_for_accounting
                        .credit_payment
                        .where(supplier: supplier)
                        .joins(:daily_report)
                        .where(daily_reports: { report_date: start_date..end_date })

      expenses.find_each do |expense|
        expense.process_accounting!(current_employee, {})
      end

      redirect_to accounting_expenses_path(tab: "invoices"),
                  notice: "#{supplier.name}の#{expenses.count}件を処理しました"
    end

    # 精算処理
    def reimburse
      expense = Expense.find(params[:id])
      expense.reimburse!

      redirect_to accounting_expenses_path(tab: "cash"),
                  notice: "精算処理を完了しました"
    end

    # 一括精算
    def bulk_reimburse
      expense_ids = params[:expense_ids] || []
      count = 0

      Expense.where(id: expense_ids).needs_reimbursement.find_each do |expense|
        expense.reimburse!
        count += 1
      end

      redirect_to accounting_expenses_path(tab: "cash"),
                  notice: "#{count}件の精算処理を完了しました"
    end

    # freee/MoneyForward用CSVエクスポート
    def export
      @expenses = Expense.includes(:project, :daily_report, :supplier)
                         .accounting_processed

      if params[:year].present? && params[:month].present?
        start_date = Date.new(params[:year].to_i, params[:month].to_i, 1)
        end_date = start_date.end_of_month
        @expenses = @expenses.where(processed_at: start_date.beginning_of_day..end_date.end_of_day)
      end

      format = params[:format_type] || "freee"

      csv_data = case format
                 when "freee"
                   generate_freee_csv(@expenses)
                 when "moneyforward"
                   generate_moneyforward_csv(@expenses)
                 else
                   generate_csv(@expenses)
                 end

      send_data csv_data,
                filename: "expenses_#{format}_#{Date.current}.csv",
                type: "text/csv; charset=shift_jis"
    end

    private

    def set_expense
      @expense = Expense.find(params[:id])
    end

    def expense_params
      params.require(:expense).permit(:account_code, :tax_category, :accounting_note)
    end

    def determine_tab(expense)
      if expense.credit_payment?
        "invoices"
      elsif expense.card_payment?
        "card"
      else
        "cash"
      end
    end

    # 請求書突合（掛け払い）
    def load_invoice_expenses
      @expenses = Expense.includes(:project, :daily_report, :payer, :supplier)
                         .ready_for_accounting
                         .credit_payment
                         .order(created_at: :desc)

      # 仕入先別にグループ化
      @expenses_by_supplier = @expenses.group_by(&:supplier)
      @total_amount = @expenses.sum(:amount)
    end

    # カード明細（カード払い）
    def load_card_expenses
      @expenses = Expense.includes(:project, :daily_report, :payer, :supplier)
                         .ready_for_accounting
                         .card_payment
                         .order(created_at: :desc)

      @total_amount = @expenses.sum(:amount)
      @expenses_by_category = @expenses.reorder(nil).group(:category).sum(:amount)
    end

    # 現金・立替
    def load_cash_expenses
      @expenses = Expense.includes(:project, :daily_report, :payer)
                         .ready_for_accounting
                         .cash_payment
                         .order(created_at: :desc)

      @total_amount = @expenses.sum(:amount)
      @expenses_by_category = @expenses.reorder(nil).group(:category).sum(:amount)

      # 精算待ちリスト
      @needs_reimbursement = Expense.needs_reimbursement
                                    .includes(:project, :payer)
                                    .order(created_at: :desc)
    end

    def generate_csv(expenses)
      require "csv"
      CSV.generate do |csv|
        csv << %w[日付 案件コード 案件名 カテゴリ 内容 金額 支払方法 仕入先 勘定科目 税区分 レシート]
        expenses.each do |e|
          csv << [
            e.daily_report&.report_date&.strftime("%Y-%m-%d"),
            e.project&.code,
            e.project&.name,
            e.category_label,
            e.description,
            e.amount.to_i,
            e.payment_method_label,
            e.supplier&.name,
            e.account_code_name,
            e.tax_category_label,
            e.receipt_attached? ? "○" : ""
          ]
        end
      end
    end

    def generate_freee_csv(expenses)
      require "csv"
      CSV.generate do |csv|
        csv << %w[取引日 勘定科目 税区分 金額 摘要 取引先]
        expenses.each do |e|
          csv << [
            e.daily_report&.report_date&.strftime("%Y-%m-%d") || e.created_at.to_date.strftime("%Y-%m-%d"),
            e.freee_account_name,
            e.tax_category == "taxable" ? "課税仕入10%" : "対象外",
            e.amount.to_i,
            "#{e.project&.name} #{e.description}".strip,
            e.supplier&.name || e.payer&.name || ""
          ]
        end
      end
    end

    def generate_moneyforward_csv(expenses)
      require "csv"
      CSV.generate do |csv|
        csv << %w[取引日 借方勘定科目 借方金額 貸方勘定科目 貸方金額 摘要]
        expenses.each do |e|
          csv << [
            e.daily_report&.report_date&.strftime("%Y/%m/%d") || e.created_at.to_date.strftime("%Y/%m/%d"),
            e.moneyforward_account_name,
            e.amount.to_i,
            payment_method_to_account(e.payment_method),
            e.amount.to_i,
            "#{e.project&.name} #{e.description}".strip
          ]
        end
      end
    end

    def payment_method_to_account(method)
      case method
      when "cash"
        "現金"
      when "company_card", "gas_card", "etc_card"
        "未払金"
      when "advance"
        "立替金"
      when "credit"
        "買掛金"
      else
        "現金"
      end
    end
  end
end
