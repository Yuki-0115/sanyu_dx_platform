# frozen_string_literal: true

module ScheduleHelper
  # 国民の祝日かどうかを判定
  def national_holiday?(date)
    return false unless defined?(HolidayJp)

    HolidayJp.holiday?(date)
  end

  # 国民の祝日名を取得
  def national_holiday_name(date)
    return nil unless defined?(HolidayJp)

    holiday = HolidayJp.between(date, date).first
    holiday&.name
  end

  # 会社休日かどうかを判定（作業員用）
  def worker_holiday?(date)
    CompanyHoliday.holiday?(date, calendar_type: "worker")
  end

  # 会社休日かどうかを判定（事務用）
  def office_holiday?(date)
    CompanyHoliday.holiday?(date, calendar_type: "office")
  end

  # 祝日（国民の祝日 OR 会社休日）かどうかを判定
  # calendar_type: nil = 国民の祝日のみ, "worker" = 作業員用休日含む, "office" = 事務用休日含む
  def holiday?(date, calendar_type: nil)
    return true if national_holiday?(date)
    return CompanyHoliday.holiday?(date, calendar_type: calendar_type) if calendar_type

    false
  end

  # 祝日名を取得
  def holiday_name(date, calendar_type: nil)
    # 国民の祝日を優先
    national_name = national_holiday_name(date)
    return national_name if national_name

    # 会社休日名
    CompanyHoliday.holiday_name(date, calendar_type: calendar_type) if calendar_type
  end

  # 日付の色クラスを取得（日曜・祝日は赤、土曜は青）
  def date_color_class(date, calendar_type: nil)
    if date.sunday? || holiday?(date, calendar_type: calendar_type)
      "text-red-600"
    elsif date.saturday?
      "text-blue-600"
    else
      "text-gray-700"
    end
  end

  # 日付セルの背景色クラス（今日ハイライト + 祝日）
  def date_cell_class(date, is_today: false, calendar_type: nil)
    classes = []
    classes << "bg-blue-50" if is_today
    classes << "bg-red-50" if holiday?(date, calendar_type: calendar_type) && !is_today
    classes.join(" ")
  end
end
