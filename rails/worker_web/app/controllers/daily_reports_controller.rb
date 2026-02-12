# frozen_string_literal: true

class DailyReportsController < ApplicationController
  before_action :set_daily_report, only: [:show, :edit, :update, :confirm]

  def index
    @daily_reports = current_worker.daily_reports_as_foreman
                                    .includes(:project)
                                    .by_date
                                    .limit(50)
  end

  def show
  end

  def new
    @projects = available_projects
    @employees = available_employees
    @partners = Partner.order(:name)
    @daily_report = DailyReport.new(
      foreman: current_worker,
      report_date: Date.current
    )
    @daily_report.attendances.build(attendance_type: "full", work_category: "work")
  end

  def create
    @daily_report = DailyReport.new(daily_report_params)
    @daily_report.foreman = current_worker

    if @daily_report.save
      redirect_to daily_report_path(@daily_report), notice: "日報を作成しました"
    else
      @projects = available_projects
      @employees = available_employees
      @partners = Partner.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @projects = available_projects
    @employees = available_employees
    @partners = Partner.order(:name)
  end

  def update
    if @daily_report.update(daily_report_params)
      redirect_to daily_report_path(@daily_report), notice: "日報を更新しました"
    else
      @projects = available_projects
      @employees = available_employees
      @partners = Partner.order(:name)
      render :edit, status: :unprocessable_entity
    end
  end

  def confirm
    if @daily_report.draft?
      @daily_report.confirm!
      redirect_to daily_report_path(@daily_report), notice: "日報を確定しました"
    else
      redirect_to daily_report_path(@daily_report), alert: "この日報は既に確定済みです"
    end
  end

  private

  def set_daily_report
    @daily_report = current_worker.daily_reports_as_foreman.find(params[:id])
  end

  def available_projects
    projects = Project.where(status: %w[ordered preparing in_progress]).order(:name)
    # 案件ごとの外注常用単価を取得（予算テーブルから直接参照）
    project_ids = projects.pluck(:id)
    @outsourcing_unit_prices = if project_ids.any?
      ActiveRecord::Base.connection.select_all(
        ActiveRecord::Base.sanitize_sql_array(
          ["SELECT project_id, outsourcing_unit_price FROM budgets WHERE project_id IN (?)", project_ids]
        )
      ).each_with_object({}) { |row, h| h[row["project_id"]] = row["outsourcing_unit_price"].to_i }
    else
      {}
    end
    @outsourcing_unit_prices.default = 18_000 # デフォルト単価
    projects
  end

  def available_employees
    Worker.where(employment_type: %w[regular temporary]).order(:name)
  end

  def daily_report_params
    params.require(:daily_report).permit(
      :report_date, :project_id, :weather, :work_content, :notes,
      :is_external, :external_site_name,
      :materials_used, :machines_used, :labor_details, :outsourcing_details,
      :transportation_cost, :labor_cost, :material_cost, :outsourcing_cost,
      :machinery_own_cost, :machinery_rental_cost,
      :fuel_type, :fuel_quantity, :fuel_amount, :fuel_receipt,
      :highway_count, :highway_amount, :highway_route, :highway_receipt,
      photos: [],
      attendances_attributes: [:id, :employee_id, :partner_worker_name, :attendance_type,
        :work_category, :hours_worked, :start_time, :end_time, :break_minutes,
        :overtime_minutes, :night_minutes, :travel_distance, :travel_minutes, :site_note, :_destroy],
      expenses_attributes: [:id, :expense_type, :category, :description, :amount, :amount_pending,
        :payment_method, :payee_name, :voucher_number, :receipt, :_destroy],
      outsourcing_entries_attributes: [:id, :partner_id, :partner_name, :billing_type,
        :headcount, :attendance_type, :contract_amount, :quantity, :unit, :unit_price, :work_description, :_destroy],
      fuel_entries_attributes: [:id, :fuel_type, :quantity, :amount, :_destroy],
      highway_entries_attributes: [:id, :amount, :route_from, :route_to, :_destroy]
    )
  end
end
