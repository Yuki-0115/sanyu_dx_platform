# frozen_string_literal: true

class ScheduleController < ApplicationController
  authorize_with :schedule
  before_action :authorize_edit!, only: %i[save_cell bulk_assign remove_assignment save_schedule_note
                                           save_outsourcing remove_outsourcing]

  def index
    # 週の開始日を設定
    @current_week_start = if params[:week].present?
                            Date.parse(params[:week]).beginning_of_week(:sunday)
                          else
                            Date.current.beginning_of_week(:sunday)
                          end
    @week_dates = (0..6).map { |i| @current_week_start + i.days }

    # 進行中の案件
    @projects = Project.where(status: %w[ordered preparing in_progress])
                       .includes(:client)
                       .order(:scheduled_start_date, :name)

    # 作業員リスト（正社員・仮社員のみ。外注は別扱い）
    @employees = Employee.where(role: %w[construction worker engineering])
                         .where(employment_type: %w[regular temporary])
                         .order(:employment_type, :name)

    @regular_employees = @employees.select { |e| e.employment_type == "regular" }
    @temporary_employees = @employees.select { |e| e.employment_type == "temporary" }

    # 協力会社リスト（外注用）
    @partners = Partner.order(:name)

    # 週間スケジュールデータを取得（社員）
    @schedules = WorkSchedule.for_date_range(@week_dates.first..@week_dates.last)
                             .includes(:employee, :project)

    # スケジュールを [project_id, date, shift] でグルーピング
    @schedule_map = {}
    @schedules.each do |s|
      key = [s.project_id, s.scheduled_date, s.shift]
      @schedule_map[key] ||= []
      @schedule_map[key] << s
    end

    # 外注スケジュールデータを取得
    @outsourcing_schedules = OutsourcingSchedule.for_date_range(@week_dates.first..@week_dates.last)
                                                 .includes(:partner, :project)

    # 外注スケジュールを [project_id, date, shift] でグルーピング
    @outsourcing_map = {}
    @outsourcing_schedules.each do |os|
      key = [os.project_id, os.scheduled_date, os.shift]
      @outsourcing_map[key] ||= []
      @outsourcing_map[key] << os
    end

    # 日付ごとの重複チェック（日勤・夜勤両方に入っている社員）
    @overlapping_employees = build_overlapping_employees(@week_dates)

    # 日付ごとの残り人数
    @remaining_by_date = build_remaining_by_date(@week_dates)

    # 備考データ
    @notes = DailyScheduleNote.for_date_range(@week_dates.first..@week_dates.last)
    @notes_map = @notes.index_by { |n| [n.project_id, n.scheduled_date] }
  end

  # GET /schedule/cell_data - セルのデータ取得
  def cell_data
    date = Date.parse(params[:date])
    project_id = params[:project_id]

    day_schedules = WorkSchedule.where(scheduled_date: date, shift: "day", project_id: project_id)
                                .includes(:employee)
    night_schedules = WorkSchedule.where(scheduled_date: date, shift: "night", project_id: project_id)
                                  .includes(:employee)

    day_outsourcing = OutsourcingSchedule.where(scheduled_date: date, shift: "day", project_id: project_id)
                                         .includes(:partner)
    night_outsourcing = OutsourcingSchedule.where(scheduled_date: date, shift: "night", project_id: project_id)
                                           .includes(:partner)

    render json: {
      day: day_schedules.map { |s| schedule_json(s) },
      night: night_schedules.map { |s| schedule_json(s) },
      day_outsourcing: day_outsourcing.map { |os| outsourcing_json(os) },
      night_outsourcing: night_outsourcing.map { |os| outsourcing_json(os) }
    }
  end

  # POST /schedule/save_cell - セル保存（作業員リスト更新）
  def save_cell
    date = Date.parse(params[:date])
    project_id = params[:project_id]
    shift = params[:shift]
    employee_ids = params[:employee_ids] || []
    roles = params[:roles] || {}

    # 既存のスケジュールをクリア
    WorkSchedule.where(scheduled_date: date, shift: shift, project_id: project_id).destroy_all

    # 新しいスケジュールを作成
    created = []
    errors = []

    employee_ids.each do |emp_id|
      schedule = WorkSchedule.new(
        scheduled_date: date,
        shift: shift,
        project_id: project_id,
        employee_id: emp_id,
        role: roles[emp_id.to_s] || "worker"
      )

      if schedule.save
        created << schedule
      else
        emp = Employee.find_by(id: emp_id)
        errors << "#{emp&.name || '不明'}: #{schedule.errors.full_messages.join(', ')}"
      end
    end

    if errors.empty?
      render json: { success: true, count: created.size }
    else
      render json: { success: false, errors: errors }, status: :unprocessable_entity
    end
  rescue StandardError => e
    render json: { success: false, error: e.message }, status: :unprocessable_entity
  end

  # POST /schedule/save_outsourcing - 外注スケジュール保存
  def save_outsourcing
    date = Date.parse(params[:date])
    project_id = params[:project_id]
    shift = params[:shift]
    outsourcing_entries = params[:outsourcing_entries] || []

    # 既存の外注スケジュールをクリア
    OutsourcingSchedule.where(scheduled_date: date, shift: shift, project_id: project_id).destroy_all

    # 新しい外注スケジュールを作成
    created = []
    errors = []

    outsourcing_entries.each do |entry|
      partner_id = entry[:partner_id]
      next if partner_id.blank?

      os = OutsourcingSchedule.new(
        scheduled_date: date,
        shift: shift,
        project_id: project_id,
        partner_id: partner_id,
        headcount: entry[:headcount].to_i.positive? ? entry[:headcount].to_i : 1,
        billing_type: entry[:billing_type] || "man_days",
        notes: entry[:notes]
      )

      if os.save
        created << os
      else
        partner = Partner.find_by(id: partner_id)
        errors << "#{partner&.name || '不明'}: #{os.errors.full_messages.join(', ')}"
      end
    end

    if errors.empty?
      render json: { success: true, count: created.size }
    else
      render json: { success: false, errors: errors }, status: :unprocessable_entity
    end
  rescue StandardError => e
    render json: { success: false, error: e.message }, status: :unprocessable_entity
  end

  # DELETE /schedule/remove_outsourcing/:id - 外注配置解除
  def remove_outsourcing
    os = OutsourcingSchedule.find(params[:id])
    os.destroy!
    render json: { success: true }
  rescue ActiveRecord::RecordNotFound
    render json: { success: false, error: "配置が見つかりません" }, status: :not_found
  end

  # GET /schedule/remaining_workers
  def remaining_workers
    date = params[:date].present? ? Date.parse(params[:date]) : Date.current
    shift = params[:shift] || "day"

    # 作業可能な社員（正社員・仮社員のみ）
    available_employees = Employee.where(role: %w[construction worker engineering])
                                  .where(employment_type: %w[regular temporary])

    # その日に既に配置されている社員
    assigned_ids = WorkSchedule.where(scheduled_date: date, shift: shift).pluck(:employee_id)

    remaining = available_employees.where.not(id: assigned_ids)

    render json: {
      date: date.strftime("%Y-%m-%d"),
      shift: shift,
      total: available_employees.count,
      assigned: assigned_ids.size,
      remaining: remaining.count,
      remaining_employees: remaining.map { |e| { id: e.id, name: e.name, employment_type: e.employment_type } }
    }
  end

  # GET /schedule/employee_schedule/available - 残り作業員取得
  def available_workers
    date = params[:date].present? ? Date.parse(params[:date]) : Date.current

    # 作業可能な社員（正社員・仮社員のみ）
    available_employees = Employee.where(role: %w[construction worker engineering])
                                  .where(employment_type: %w[regular temporary])

    # その日に既に配置されている社員（日勤・夜勤両方）
    assigned_ids = WorkSchedule.where(scheduled_date: date).pluck(:employee_id).uniq

    remaining = available_employees.where.not(id: assigned_ids)

    render json: {
      available: remaining.map { |e| { id: e.id, name: e.name } }
    }
  end

  # GET /schedule/project_assignments/:id - 案件の配置情報取得
  def project_assignments
    project_id = params[:id]
    schedules = WorkSchedule.where(project_id: project_id).includes(:employee)

    # dandori_controller.js が期待する形式に変換
    assignments = schedules.map do |s|
      {
        id: s.id,
        employee_id: s.employee_id,
        start_date: s.scheduled_date.strftime("%Y-%m-%d"),
        end_date: s.scheduled_date.strftime("%Y-%m-%d"),
        shift: s.shift,
        role: s.role || "worker"
      }
    end

    render json: { assignments: assignments }
  end

  # POST /schedule/bulk_assign - 一括配置
  def bulk_assign
    project_id = params[:project_id]
    employee_ids = params[:employee_ids] || []
    start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : nil
    end_date = params[:end_date].present? ? Date.parse(params[:end_date]) : nil
    shift = params[:shift] || "day"
    role = params[:role] || "worker"
    roles = params[:roles] || {}

    # 日付範囲を計算（同じ日なら1日のみ）
    dates = if start_date && end_date
              (start_date..end_date).to_a
            elsif start_date
              [start_date]
            else
              [Date.current]
            end

    created = 0
    errors = []

    dates.each do |date|
      employee_ids.each do |emp_id|
        # 既存の配置を確認
        existing = WorkSchedule.find_by(
          scheduled_date: date,
          shift: shift,
          project_id: project_id,
          employee_id: emp_id
        )
        next if existing

        # 新規作成
        emp_role = roles[emp_id.to_s] || role
        schedule = WorkSchedule.new(
          scheduled_date: date,
          shift: shift,
          project_id: project_id,
          employee_id: emp_id,
          role: emp_role
        )

        if schedule.save
          created += 1
        else
          emp = Employee.find_by(id: emp_id)
          errors << "#{emp&.name}: #{schedule.errors.full_messages.join(', ')}"
        end
      end
    end

    if errors.empty?
      render json: {
        success: true,
        message: "#{created}件の配置を作成しました",
        count: created
      }
    else
      render json: { success: false, errors: errors }, status: :unprocessable_entity
    end
  rescue StandardError => e
    render json: { success: false, error: e.message }, status: :unprocessable_entity
  end

  # DELETE /schedule/remove_assignment/:id - 配置解除
  def remove_assignment
    schedule = WorkSchedule.find(params[:id])
    schedule.destroy!
    render json: { success: true }
  rescue ActiveRecord::RecordNotFound
    render json: { success: false, error: "配置が見つかりません" }, status: :not_found
  end

  # GET /schedule/schedule_note - 備考取得
  def schedule_note
    project_id = params[:project_id]
    date = Date.parse(params[:date])

    note = DailyScheduleNote.find_by(project_id: project_id, scheduled_date: date)

    if note
      render json: {
        note: {
          id: note.id,
          work_content: note.work_content,
          vehicles: note.vehicles,
          equipment: note.equipment,
          heavy_equipment_transport: note.heavy_equipment_transport,
          notes: note.notes
        }
      }
    else
      render json: { note: nil }
    end
  end

  # POST /schedule/save_schedule_note - 備考保存
  def save_schedule_note
    project_id = params[:project_id]
    date = Date.parse(params[:date])

    note = DailyScheduleNote.find_or_initialize_by(project_id: project_id, scheduled_date: date)
    note.assign_attributes(
      work_content: params[:work_content],
      vehicles: params[:vehicles],
      equipment: params[:equipment],
      heavy_equipment_transport: params[:heavy_equipment_transport],
      notes: params[:notes]
    )

    if note.save
      render json: { success: true, id: note.id }
    else
      render json: { success: false, errors: note.errors.full_messages }, status: :unprocessable_entity
    end
  rescue StandardError => e
    render json: { success: false, error: e.message }, status: :unprocessable_entity
  end

  private

  def authorize_edit!
    unless current_employee.can_edit?(:schedule)
      respond_to do |format|
        format.html { redirect_to schedule_path, alert: "編集権限がありません" }
        format.json { render json: { success: false, error: "編集権限がありません" }, status: :forbidden }
      end
    end
  end

  def schedule_json(schedule)
    {
      id: schedule.id,
      employee_id: schedule.employee_id,
      employee_name: schedule.employee.name,
      employment_type: schedule.employee.employment_type,
      scheduled_date: schedule.scheduled_date.strftime("%Y-%m-%d"),
      shift: schedule.shift,
      project_id: schedule.project_id,
      role: schedule.role || "worker"
    }
  end

  def outsourcing_json(os)
    {
      id: os.id,
      partner_id: os.partner_id,
      partner_name: os.partner.name,
      scheduled_date: os.scheduled_date.strftime("%Y-%m-%d"),
      shift: os.shift,
      project_id: os.project_id,
      headcount: os.headcount,
      billing_type: os.billing_type,
      notes: os.notes,
      display_label: os.display_label,
      short_label: os.short_label
    }
  end

  # 日付ごとに日勤・夜勤両方に配置されている社員IDを取得
  def build_overlapping_employees(dates)
    result = {}

    dates.each do |date|
      day_ids = WorkSchedule.where(scheduled_date: date, shift: "day").pluck(:employee_id).to_set
      night_ids = WorkSchedule.where(scheduled_date: date, shift: "night").pluck(:employee_id).to_set
      result[date] = day_ids & night_ids
    end

    result
  end

  # 日付ごとの残り人数を計算
  def build_remaining_by_date(dates)
    result = {}

    available_count = Employee.where(role: %w[construction worker engineering])
                              .where(employment_type: %w[regular temporary])
                              .count

    dates.each do |date|
      day_assigned = WorkSchedule.where(scheduled_date: date, shift: "day").select(:employee_id).distinct.count
      night_assigned = WorkSchedule.where(scheduled_date: date, shift: "night").select(:employee_id).distinct.count

      result[date] = {
        day: available_count - day_assigned,
        night: available_count - night_assigned,
        day_assigned: day_assigned,
        night_assigned: night_assigned,
        total: available_count
      }
    end

    result
  end
end
