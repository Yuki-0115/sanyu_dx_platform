# frozen_string_literal: true

# 日報コントローラーの共通ロジック
module DailyReportActions
  extend ActiveSupport::Concern

  included do
    before_action :authorize_daily_reports_access
  end

  private

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

  def handle_update
    was_finalized = @daily_report.finalized?

    if @daily_report.update(daily_report_params)
      if was_finalized
        @daily_report.update!(
          status: "revised",
          revised_at: Time.current,
          revised_by: current_employee
        )
        yield "修正しました（修正履歴が記録されます）"
      else
        yield "更新しました"
      end
    else
      build_attendances
      render :edit, status: :unprocessable_entity
    end
  end

  def handle_confirm
    if @daily_report.status == "draft"
      @daily_report.confirm!
      yield "確定しました"
    else
      yield nil, "この日報は既に確定済みです"
    end
  end

  def base_daily_report_params
    [
      :report_date, :weather, :work_content, :notes,
      :materials_used, :machines_used, :labor_details,
      :outsourcing_details, :transportation_cost,
      :labor_cost, :material_cost, :outsourcing_cost,
      photos: []
    ]
  end

  def attendance_params
    { attendances_attributes: %i[id employee_id partner_worker_name attendance_type hours_worked start_time end_time travel_distance _destroy] }
  end

  def expense_params
    { expenses_attributes: %i[id expense_type category description amount payment_method receipt _destroy] }
  end
end
