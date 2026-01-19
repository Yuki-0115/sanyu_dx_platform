# frozen_string_literal: true

class Attendance < ApplicationRecord
  include TenantScoped

  # Constants
  ATTENDANCE_TYPES = %w[full half].freeze
  ATTENDANCE_LABELS = {
    "full" => "1日",
    "half" => "半日"
  }.freeze

  # 勤務区分
  WORK_CATEGORIES = %w[work day_off paid_leave absence substitute_holiday].freeze
  WORK_CATEGORY_LABELS = {
    "work" => "出勤",
    "day_off" => "公休",
    "paid_leave" => "有給",
    "absence" => "欠勤",
    "substitute_holiday" => "振休"
  }.freeze

  # 時間帯設定（分単位）
  WORK_START_HOUR = 8   # 基本就業開始 08:00
  WORK_END_HOUR = 17    # 基本就業終了 17:00
  NIGHT_START_HOUR = 22 # 深夜開始 22:00
  NIGHT_END_HOUR = 5    # 深夜終了 05:00

  # Associations
  belongs_to :daily_report
  belongs_to :employee

  # Callbacks
  before_save :auto_calculate_hours, if: :should_auto_calculate?

  # Validations
  validates :attendance_type, presence: true, inclusion: { in: ATTENDANCE_TYPES }
  validates :employee_id, presence: true, uniqueness: { scope: %i[tenant_id daily_report_id] }
  validates :work_category, inclusion: { in: WORK_CATEGORIES }, allow_blank: true

  # Scopes
  scope :present, -> { where(attendance_type: %w[full half]) }
  scope :by_employee, ->(employee) { where(employee: employee) }

  # Instance methods
  def present?
    attendance_type.in?(%w[full half])
  end

  # 作業員名を取得
  def worker_name
    employee&.name || "不明"
  end

  # 表示用ラベル
  def attendance_label
    ATTENDANCE_LABELS[attendance_type] || attendance_type
  end

  # 人工計算（1日=1人工、半日=0.5人工）
  def man_days
    case attendance_type
    when "full"
      1
    when "half"
      0.5
    else
      0
    end
  end

  # 勤務区分ラベル
  def work_category_label
    WORK_CATEGORY_LABELS[work_category] || work_category || "-"
  end

  # 休憩時間を時間:分形式で表示
  def break_time_display
    return "-" if break_minutes.blank? || break_minutes.zero?

    hours = break_minutes / 60
    mins = break_minutes % 60
    format("%d:%02d", hours, mins)
  end

  # 基本就業時間を計算（分単位）- 08:00-17:00の時間帯のみ
  def regular_work_minutes
    return 0 if start_time.blank? || end_time.blank?

    breakdown = calculate_time_breakdown_for_display
    breakdown[:regular_minutes]
  end

  # 合計就業時間（分単位）
  def total_work_minutes
    return 0 if start_time.blank? || end_time.blank?

    breakdown = calculate_time_breakdown_for_display
    breakdown[:total_minutes]
  end

  # 表示用の時間内訳を計算
  def calculate_time_breakdown_for_display
    return { regular_minutes: 0, overtime_minutes: 0, night_minutes: 0, total_minutes: 0 } if start_time.blank? || end_time.blank?

    start_mins = start_time.hour * 60 + start_time.min
    end_mins = end_time.hour * 60 + end_time.min
    end_mins += 24 * 60 if end_mins < start_mins

    break_mins = break_minutes || 60

    regular = 0
    overtime = 0
    night = 0

    # 各分を時間帯に振り分け
    current = start_mins
    while current < end_mins
      hour_of_day = (current / 60) % 24

      if hour_of_day >= NIGHT_START_HOUR || hour_of_day < NIGHT_END_HOUR
        night += 1
      elsif hour_of_day >= WORK_END_HOUR || hour_of_day < WORK_START_HOUR
        overtime += 1
      else
        regular += 1
      end

      current += 1
    end

    # 休憩時間を差し引く
    # 基本時間がある場合は基本から優先、ない場合（夜勤など）は最も多い時間帯から引く
    remaining_break = break_mins

    if regular > 0
      # 日勤パターン: 基本→残業→深夜の順
      if regular >= remaining_break
        regular -= remaining_break
        remaining_break = 0
      else
        remaining_break -= regular
        regular = 0
      end

      if remaining_break > 0 && overtime > 0
        if overtime >= remaining_break
          overtime -= remaining_break
          remaining_break = 0
        else
          remaining_break -= overtime
          overtime = 0
        end
      end

      if remaining_break > 0 && night > 0
        night = [night - remaining_break, 0].max
      end
    else
      # 夜勤パターン: 最も多い時間帯から引く
      if night >= overtime
        if night >= remaining_break
          night -= remaining_break
        else
          remaining_break -= night
          night = 0
          overtime = [overtime - remaining_break, 0].max
        end
      else
        if overtime >= remaining_break
          overtime -= remaining_break
        else
          remaining_break -= overtime
          overtime = 0
          night = [night - remaining_break, 0].max
        end
      end
    end

    {
      regular_minutes: regular,
      overtime_minutes: overtime,
      night_minutes: night,
      total_minutes: regular + overtime + night
    }
  end

  # 時間を「HH:MM」形式で表示
  def minutes_to_time_display(minutes)
    return "-" if minutes.blank? || minutes.zero?

    hours = minutes / 60
    mins = minutes % 60
    format("%d:%02d", hours, mins)
  end

  # 時間を自動計算するクラスメソッド（Stimulus用）
  def self.calculate_time_breakdown(start_time_str, end_time_str, break_mins = 60)
    return {} if start_time_str.blank? || end_time_str.blank?

    start_hour, start_min = start_time_str.split(":").map(&:to_i)
    end_hour, end_min = end_time_str.split(":").map(&:to_i)

    start_mins = start_hour * 60 + start_min
    end_mins = end_hour * 60 + end_min
    end_mins += 24 * 60 if end_mins < start_mins # 翌日にまたがる場合

    total_mins = end_mins - start_mins - break_mins.to_i
    return {} if total_mins <= 0

    # 時間帯別に計算
    regular = 0
    overtime = 0
    night = 0

    current = start_mins
    while current < end_mins
      hour_of_day = (current / 60) % 24

      # 深夜時間帯 (22:00-05:00)
      if hour_of_day >= NIGHT_START_HOUR || hour_of_day < NIGHT_END_HOUR
        night += 1
      # 残業時間帯 (17:00-22:00 or 05:00-08:00)
      elsif hour_of_day >= WORK_END_HOUR || hour_of_day < WORK_START_HOUR
        overtime += 1
      # 基本就業時間帯 (08:00-17:00)
      else
        regular += 1
      end

      current += 1
    end

    # 休憩時間を差し引く
    # 基本時間がある場合は基本から優先、ない場合（夜勤など）は最も多い時間帯から引く
    remaining_break = break_mins.to_i

    if regular > 0
      # 日勤パターン: 基本→残業→深夜の順
      if regular >= remaining_break
        regular -= remaining_break
        remaining_break = 0
      else
        remaining_break -= regular
        regular = 0
      end

      if remaining_break > 0 && overtime > 0
        if overtime >= remaining_break
          overtime -= remaining_break
          remaining_break = 0
        else
          remaining_break -= overtime
          overtime = 0
        end
      end

      if remaining_break > 0 && night > 0
        night = [night - remaining_break, 0].max
      end
    else
      # 夜勤パターン: 最も多い時間帯から引く
      if night >= overtime
        if night >= remaining_break
          night -= remaining_break
        else
          remaining_break -= night
          night = 0
          overtime = [overtime - remaining_break, 0].max
        end
      else
        if overtime >= remaining_break
          overtime -= remaining_break
        else
          remaining_break -= overtime
          overtime = 0
          night = [night - remaining_break, 0].max
        end
      end
    end

    {
      regular_minutes: regular,
      overtime_minutes: overtime,
      night_minutes: night,
      total_minutes: regular + overtime + night
    }
  end

  private

  def should_auto_calculate?
    start_time.present? && end_time.present? && work_category == "work"
  end

  def auto_calculate_hours
    breakdown = calculate_time_breakdown_instance
    return if breakdown.empty?

    self.overtime_minutes = breakdown[:overtime_minutes]
    self.night_minutes = breakdown[:night_minutes]
  end

  def calculate_time_breakdown_instance
    return {} if start_time.blank? || end_time.blank?

    start_mins = start_time.hour * 60 + start_time.min
    end_mins = end_time.hour * 60 + end_time.min
    end_mins += 24 * 60 if end_mins < start_mins

    break_mins = break_minutes || 60
    total_mins = end_mins - start_mins - break_mins
    return {} if total_mins <= 0

    regular = 0
    overtime = 0
    night = 0

    current = start_mins
    while current < end_mins
      hour_of_day = (current / 60) % 24

      if hour_of_day >= NIGHT_START_HOUR || hour_of_day < NIGHT_END_HOUR
        night += 1
      elsif hour_of_day >= WORK_END_HOUR || hour_of_day < WORK_START_HOUR
        overtime += 1
      else
        regular += 1
      end

      current += 1
    end

    regular = [regular - break_mins, 0].max

    {
      regular_minutes: regular,
      overtime_minutes: overtime,
      night_minutes: night,
      total_minutes: regular + overtime + night
    }
  end

  def calculate_total_minutes
    return 0 if start_time.blank? || end_time.blank?

    start_mins = start_time.hour * 60 + start_time.min
    end_mins = end_time.hour * 60 + end_time.min

    # 翌日にまたがる場合
    end_mins += 24 * 60 if end_mins < start_mins

    end_mins - start_mins
  end
end
