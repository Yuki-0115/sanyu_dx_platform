# frozen_string_literal: true

class ManagementDashboardController < ApplicationController
  before_action :authorize_management_access

  def index
    # 期間設定（デフォルト: 今月）
    @current_month = Date.current.beginning_of_month
    @selected_month = params[:month].present? ? Date.parse(params[:month]) : @current_month

    # === 売上・利益サマリー ===
    # 受注金額（今月受注）
    @monthly_orders = Project.where(
      status: %w[ordered preparing in_progress completed invoiced paid closed]
    ).where("created_at >= ? AND created_at < ?", @selected_month, @selected_month.next_month)
    @monthly_order_amount = @monthly_orders.sum(:order_amount) || 0

    # 請求金額（今月発行）
    @monthly_invoices = Invoice.where(status: %w[issued waiting paid])
                               .where("issued_date >= ? AND issued_date < ?", @selected_month, @selected_month.next_month)
    @monthly_invoice_amount = @monthly_invoices.sum(:total_amount) || 0

    # 入金金額（今月入金）
    @monthly_payments = Payment.where("payment_date >= ? AND payment_date < ?", @selected_month, @selected_month.next_month)
    @monthly_payment_amount = @monthly_payments.sum(:amount) || 0

    # 原価（今月確定日報）
    @monthly_cost = DailyReport.where(status: %w[confirmed revised])
                               .where("report_date >= ? AND report_date < ?", @selected_month, @selected_month.next_month)
                               .sum("COALESCE(labor_cost, 0) + COALESCE(material_cost, 0) + COALESCE(outsourcing_cost, 0) + COALESCE(transportation_cost, 0)")

    # === 累計サマリー ===
    @total_order_amount = Project.sum(:order_amount) || 0
    @total_invoice_amount = Invoice.where(status: %w[issued waiting paid]).sum(:total_amount) || 0
    @total_paid_amount = Payment.sum(:amount) || 0
    @total_unpaid_amount = @total_invoice_amount - @total_paid_amount

    # === ステータス別案件数 ===
    @projects_by_status = Project.group(:status).count

    # === 入金待ち請求書 ===
    @unpaid_invoices = Invoice.includes(project: :client)
                              .where(status: %w[issued waiting])
                              .order(due_date: :asc)
                              .limit(10)

    # === 利益率ワースト案件（予算超過リスク） ===
    @risky_projects = Project.includes(:budget)
                             .joins(:budget)
                             .where(status: %w[in_progress])
                             .order("budgets.total_cost DESC")
                             .limit(5)

    # === 月別推移（過去6ヶ月） ===
    @monthly_trends = []
    6.times do |i|
      month = @current_month - i.months
      order_amount = Project.where("created_at >= ? AND created_at < ?", month, month.next_month).sum(:order_amount) || 0
      invoice_amount = Invoice.where(status: %w[issued waiting paid])
                              .where("issued_date >= ? AND issued_date < ?", month, month.next_month)
                              .sum(:total_amount) || 0
      payment_amount = Payment.where("payment_date >= ? AND payment_date < ?", month, month.next_month).sum(:amount) || 0

      @monthly_trends << {
        month: month,
        order_amount: order_amount,
        invoice_amount: invoice_amount,
        payment_amount: payment_amount
      }
    end
    @monthly_trends.reverse!
  end

  private

  def authorize_management_access
    unless current_employee.admin? || current_employee.management?
      redirect_to root_path, alert: "経営ダッシュボードへのアクセス権限がありません"
    end
  end
end
