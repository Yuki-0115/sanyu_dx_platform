# frozen_string_literal: true

class AllDailyReportsController < ApplicationController
  authorize_with :daily_reports

  def index
    @filter = params[:filter] || "all" # all, project, external

    # 期間フィルター（デフォルト: 今月）
    if params[:date_from].present?
      @date_from = Date.parse(params[:date_from])
    else
      @date_from = Date.current.beginning_of_month
    end

    if params[:date_to].present?
      @date_to = Date.parse(params[:date_to])
    else
      @date_to = Date.current.end_of_month
    end

    # 現場フィルター
    @selected_project = nil
    if params[:project_id].present?
      @selected_project = Project.find_by(id: params[:project_id])
    end

    @daily_reports = DailyReport.includes(:project, :foreman)
                                .where(report_date: @date_from..@date_to)
                                .order(report_date: :desc, created_at: :desc)

    # 現場で絞り込み
    if @selected_project
      @daily_reports = @daily_reports.where(project_id: @selected_project.id)
    end

    case @filter
    when "project"
      @daily_reports = @daily_reports.where(is_external: false)
    when "external"
      @daily_reports = @daily_reports.where(is_external: true)
    end

    @total_count = @daily_reports.count
    @draft_count = @daily_reports.where(status: "draft").count
    @confirmed_count = @daily_reports.where(status: %w[confirmed revised]).count
  end

  def new
    # 案件日報 or 常用日報を選択する画面
    @projects = Project.where(status: %w[in_progress preparing]).order(:name)
  end

end
