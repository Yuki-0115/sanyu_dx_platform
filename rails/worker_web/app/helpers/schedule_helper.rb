# frozen_string_literal: true

module ScheduleHelper
  WEEKDAY_LABELS = %w[日 月 火 水 木 金 土].freeze

  def weekday_label(date)
    WEEKDAY_LABELS[date.wday]
  end

  def date_color_class(date)
    if date.sunday? || national_holiday?(date)
      "text-red-600"
    elsif date.saturday?
      "text-blue-600"
    else
      "text-gray-700"
    end
  end

  def date_cell_bg(date, today)
    return "bg-yellow-50 ring-2 ring-yellow-300" if date == today
    return "bg-red-50/50" if date.sunday? || national_holiday?(date)

    ""
  end

  def national_holiday?(date)
    HolidayJp.holiday?(date)
  rescue
    false
  end
end
