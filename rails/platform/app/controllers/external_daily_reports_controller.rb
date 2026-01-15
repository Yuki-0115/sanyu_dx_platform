# frozen_string_literal: true

class ExternalDailyReportsController < ApplicationController
  before_action :authorize_daily_reports_access
  before_action :set_daily_report, only: %i[show edit update confirm]

  def index
    @daily_reports = DailyReport.external.includes(:foreman).order(report_date: :desc)
  end

  def show; end

  def new
    @daily_report = DailyReport.new(
      foreman: current_employee,
      report_date: Date.current,
      is_external: true
    )
    build_attendances
  end

  def edit
    build_attendances
  end

  def create
    @daily_report = DailyReport.new(daily_report_params)
    @daily_report.foreman = current_employee
    @daily_report.is_external = true

    if @daily_report.save
      redirect_to external_daily_report_path(@daily_report), notice: "常用日報を作成しました"
    else
      build_attendances
      render :new, status: :unprocessable_entity
    end
  end

  def update
    was_finalized = @daily_report.finalized?

    if @daily_report.update(daily_report_params)
      if was_finalized
        @daily_report.update!(
          status: "revised",
          revised_at: Time.current,
          revised_by: current_employee
        )
        redirect_to external_daily_report_path(@daily_report), notice: "常用日報を修正しました（修正履歴が記録されます）"
      else
        redirect_to external_daily_report_path(@daily_report), notice: "常用日報を更新しました"
      end
    else
      build_attendances
      render :edit, status: :unprocessable_entity
    end
  end

  def confirm
    if @daily_report.status == "draft"
      @daily_report.confirm!
      redirect_to external_daily_report_path(@daily_report), notice: "常用日報を確定しました"
    else
      redirect_to external_daily_report_path(@daily_report), alert: "この日報は既に確定済みです"
    end
  end

  private

  def set_daily_report
    @daily_report = DailyReport.external.find(params[:id])
  end

  def authorize_daily_reports_access
    authorize_feature!(:daily_reports)
  end

  def build_attendances
    existing_employee_ids = @daily_report.attendances.map(&:employee_id)
    employees = Employee.where(role: %w[construction worker]).where.not(id: existing_employee_ids)
    employees.each do |employee|
      @daily_report.attendances.build(employee: employee, attendance_type: "absent")
    end
  end

  def daily_report_params
    params.require(:daily_report).permit(
      :report_date, :weather, :work_content, :notes,
      :external_site_name,
      :materials_used, :machines_used, :labor_details,
      :outsourcing_details, :transportation_cost,
      :labor_cost, :material_cost, :outsourcing_cost,
      attendances_attributes: %i[id employee_id partner_worker_name attendance_type hours_worked start_time end_time travel_distance _destroy]
    )
  end
end
