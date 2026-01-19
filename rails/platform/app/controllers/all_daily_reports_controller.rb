# frozen_string_literal: true

class AllDailyReportsController < ApplicationController
  before_action :authorize_daily_reports_access

  def index
    @filter = params[:filter] || "all" # all, project, external
    @date_from = params[:date_from].present? ? Date.parse(params[:date_from]) : Date.current.beginning_of_month
    @date_to = params[:date_to].present? ? Date.parse(params[:date_to]) : Date.current.end_of_month

    @daily_reports = DailyReport.includes(:project, :foreman)
                                .where(report_date: @date_from..@date_to)
                                .order(report_date: :desc, created_at: :desc)

    case @filter
    when "project"
      @daily_reports = @daily_reports.where(is_external: false)
    when "external"
      @daily_reports = @daily_reports.where(is_external: true)
    end

    @draft_count = DailyReport.where(status: "draft").count
    @confirmed_count = DailyReport.where(status: "confirmed").count
    @total_count = @daily_reports.count
  end

  def new
    # 案件日報 or 常用日報を選択する画面
    @projects = Project.where(status: %w[in_progress preparing]).order(:name)
  end

  private

  def authorize_daily_reports_access
    authorize_feature!(:daily_reports)
  end
end
