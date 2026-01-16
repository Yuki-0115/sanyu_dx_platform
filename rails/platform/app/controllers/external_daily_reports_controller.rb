# frozen_string_literal: true

class ExternalDailyReportsController < ApplicationController
  include DailyReportActions

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
    handle_update do |message|
      redirect_to external_daily_report_path(@daily_report), notice: "常用日報を#{message}"
    end
  end

  def confirm
    handle_confirm do |success_message, error_message|
      if success_message
        redirect_to external_daily_report_path(@daily_report), notice: "常用日報を#{success_message}"
      else
        redirect_to external_daily_report_path(@daily_report), alert: error_message
      end
    end
  end

  private

  def set_daily_report
    @daily_report = DailyReport.external.find(params[:id])
  end

  def daily_report_params
    params.require(:daily_report).permit(
      *base_daily_report_params,
      :external_site_name,
      **attendance_params,
      **expense_params
    )
  end
end
