# frozen_string_literal: true

class DashboardController < ApplicationController
  before_action :authorize_dashboard_access

  def index
    @employee = current_employee

    # 案件サマリー
    @projects_by_status = Project.group(:status).count
    @total_projects = Project.count
    @active_projects = Project.active.count

    # 金額サマリー
    @total_order_amount = Project.sum(:order_amount) || 0
    @total_budget_amount = Project.joins(:budget).sum("budgets.total_cost") || 0

    # 直近の日報
    @recent_reports = DailyReport.includes(:project, :foreman)
                                 .order(report_date: :desc)
                                 .limit(5)

    # 直近の案件
    @recent_projects = Project.includes(:client)
                              .order(updated_at: :desc)
                              .limit(5)

    # 直近の請求書
    @recent_invoices = Invoice.includes(project: :client)
                              .order(created_at: :desc)
                              .limit(5)

    # 請求書サマリー
    @unpaid_invoices_count = Invoice.where(status: %w[issued waiting]).count
    @unpaid_invoices_amount = Invoice.where(status: %w[issued waiting]).sum(:total_amount) || 0
  end

  private

  def authorize_dashboard_access
    authorize_feature!(:dashboard)
  end
end
