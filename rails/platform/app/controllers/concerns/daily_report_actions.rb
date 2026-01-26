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

  # 段取り表（ProjectAssignment）から出面データを事前構築
  # 既存の出面がない場合のみ、配置済み社員を自動追加
  def build_attendances
    return if @daily_report.project.nil?  # 外部現場の場合はスキップ

    existing_employee_ids = @daily_report.attendances.map(&:employee_id).compact

    # 段取り表から当日の配置済み社員を取得（正社員・仮社員のみ）
    assigned_employees = @daily_report.project
      .project_assignments
      .active_on(@daily_report.report_date)
      .includes(:employee)
      .map(&:employee)
      .select { |e| e.employment_type.in?(%w[regular temporary]) }
      .reject { |e| existing_employee_ids.include?(e.id) }

    # 配置済み社員で出面を構築（デフォルト: 1日出勤）
    assigned_employees.each do |employee|
      @daily_report.attendances.build(
        employee: employee,
        attendance_type: "full",
        hours_worked: 8
      )
    end
  end

  # 外注入力欄を構築
  def build_outsourcing_entries
    # 既存エントリがない場合のみ、空のエントリを1つ追加
    if @daily_report.outsourcing_entries.empty?
      @daily_report.outsourcing_entries.build(attendance_type: "full", headcount: 1)
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
      build_outsourcing_entries
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
      # 燃料費・高速代（カード精算）
      :fuel_type, :fuel_quantity, :fuel_amount,
      :highway_count, :highway_amount, :highway_route,
      photos: []
    ]
  end

  def attendance_params
    { attendances_attributes: %i[id employee_id partner_worker_name attendance_type work_category hours_worked start_time end_time break_minutes overtime_minutes night_minutes travel_distance travel_minutes site_note _destroy] }
  end

  def expense_params
    { expenses_attributes: %i[id expense_type category description amount payment_method payee_name voucher_number receipt voucher _destroy] }
  end

  def outsourcing_entry_params
    { outsourcing_entries_attributes: %i[id partner_id partner_name billing_type headcount attendance_type contract_amount quantity unit work_description _destroy] }
  end
end
