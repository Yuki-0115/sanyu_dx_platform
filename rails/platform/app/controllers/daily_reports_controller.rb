# frozen_string_literal: true

class DailyReportsController < ApplicationController
  before_action :authorize_daily_reports_access
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
  end

  def edit
    build_attendances
  end

  def create
    @daily_report = @project.daily_reports.build(daily_report_params)
    @daily_report.foreman = current_employee

    if @daily_report.save
      redirect_to project_daily_report_path(@project, @daily_report), notice: "日報を作成しました"
    else
      build_attendances
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @daily_report.update(daily_report_params)
      redirect_to project_daily_report_path(@project, @daily_report), notice: "日報を更新しました"
    else
      build_attendances
      render :edit, status: :unprocessable_entity
    end
  end

  def confirm
    if @daily_report.status == "draft"
      @daily_report.confirm!
      redirect_to project_daily_report_path(@project, @daily_report), notice: "日報を確定しました"
    else
      redirect_to project_daily_report_path(@project, @daily_report), alert: "この日報は既に確定済みです"
    end
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_daily_report
    @daily_report = @project.daily_reports.find(params[:id])
  end

  def authorize_daily_reports_access
    authorize_feature!(:daily_reports)
  end

  def build_attendances
    existing_employee_ids = @daily_report.attendances.map(&:employee_id)
    # Get construction workers and add them if not already present
    employees = Employee.where(role: %w[construction worker]).where.not(id: existing_employee_ids)
    employees.each do |employee|
      @daily_report.attendances.build(employee: employee, attendance_type: "absent")
    end
  end

  def daily_report_params
    params.require(:daily_report).permit(
      :report_date, :weather, :temperature_high, :temperature_low,
      :work_content, :notes,
      attendances_attributes: %i[id employee_id attendance_type start_time end_time travel_distance _destroy]
    )
  end
end
