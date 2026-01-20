# frozen_string_literal: true

class ScheduleController < ApplicationController
  authorize_with :projects

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

    # 作業員リスト（雇用形態でグループ分け）
    @employees = Employee.where(role: %w[construction worker engineering])
                         .or(Employee.where(employment_type: %w[temporary external]))
                         .order(:employment_type, :name)

    @regular_employees = @employees.select { |e| e.employment_type == "regular" }
    @temporary_employees = @employees.select { |e| e.employment_type == "temporary" }
    @external_employees = @employees.select { |e| e.employment_type == "external" }

    # 週間スケジュールデータを取得
    @schedules = WorkSchedule.for_date_range(@week_dates.first..@week_dates.last)
                             .includes(:employee, :project)

    # スケジュールを [project_id, date, shift] でグルーピング
    @schedule_map = {}
    @schedules.each do |s|
      key = [s.project_id, s.scheduled_date, s.shift]
      @schedule_map[key] ||= []
      @schedule_map[key] << s
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

    render json: {
      day: day_schedules.map { |s| schedule_json(s) },
      night: night_schedules.map { |s| schedule_json(s) }
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

  # GET /schedule/remaining_workers
  def remaining_workers
    date = params[:date].present? ? Date.parse(params[:date]) : Date.current
    shift = params[:shift] || "day"

    # 作業可能な社員
    available_employees = Employee.where(role: %w[construction worker engineering])
                                  .or(Employee.where(employment_type: %w[temporary external]))

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

    # 作業可能な社員
    available_employees = Employee.where(role: %w[construction worker engineering])
                                  .or(Employee.where(employment_type: %w[temporary external]))

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
                              .or(Employee.where(employment_type: %w[temporary external]))
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
