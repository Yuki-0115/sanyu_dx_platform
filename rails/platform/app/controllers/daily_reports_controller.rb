# frozen_string_literal: true

class DailyReportsController < ApplicationController
  include DailyReportActions

  before_action :set_project
  before_action :set_daily_report, only: %i[show edit update confirm]

  def index
    @daily_reports = @project.daily_reports.includes(:foreman).order(report_date: :desc)
  end

  def show; end

  def new
    @daily_report = @project.daily_reports.build(
      foreman: current_employee,
      report_date: Date.current
    )
    build_attendances
    build_outsourcing_entries
  end

  def edit
    build_attendances
    build_outsourcing_entries
  end

  def create
    @daily_report = @project.daily_reports.build(daily_report_params)
    @daily_report.foreman = current_employee

    if @daily_report.save
      redirect_to project_daily_report_path(@project, @daily_report), notice: "日報を作成しました"
    else
      build_attendances
      build_outsourcing_entries
      render :new, status: :unprocessable_entity
    end
  end

  def update
    handle_update do |message|
      redirect_to project_daily_report_path(@project, @daily_report), notice: "日報を#{message}"
    end
  end

  def confirm
    handle_confirm do |success_message, error_message|
      if success_message
        redirect_to project_daily_report_path(@project, @daily_report), notice: "日報を#{success_message}"
      else
        redirect_to project_daily_report_path(@project, @daily_report), alert: error_message
      end
    end
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_daily_report
    @daily_report = @project.daily_reports.find(params[:id])
  end

  def daily_report_params
    params.require(:daily_report).permit(
      *base_daily_report_params,
      **attendance_params,
      **expense_params,
      **outsourcing_entry_params
    )
  end
end
