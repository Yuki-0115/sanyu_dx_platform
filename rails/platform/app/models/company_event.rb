# frozen_string_literal: true

class CompanyEvent < ApplicationRecord
  # カレンダー種別（all = 両方に表示）
  CALENDAR_TYPES = {
    "all" => "共通",
    "worker" => "作業員用",
    "office" => "事務用"
  }.freeze

  # 色オプション
  COLORS = {
    "purple" => "紫",
    "orange" => "オレンジ",
    "pink" => "ピンク",
    "teal" => "ティール",
    "indigo" => "インディゴ"
  }.freeze

  validates :event_date, presence: true
  validates :name, presence: true
  validates :calendar_type, presence: true, inclusion: { in: CALENDAR_TYPES.keys }
  validates :color, inclusion: { in: COLORS.keys }, allow_blank: true

  scope :for_year, ->(year) { where(event_date: Date.new(year, 1, 1)..Date.new(year, 12, 31)) }
  scope :for_month, ->(date) { where(event_date: date.beginning_of_month..date.end_of_month) }
  scope :for_date, ->(date) { where(event_date: date) }
  scope :for_calendar_type, ->(type) { where(calendar_type: [type, "all"]) }
  scope :upcoming, -> { where("event_date >= ?", Date.current).order(:event_date) }

  # 指定日のイベントを取得
  def self.events_for(date, calendar_type: nil)
    scope = for_date(date)
    scope = scope.for_calendar_type(calendar_type) if calendar_type
    scope.order(:name)
  end

  # カレンダー種別ラベル
  def calendar_type_label
    CALENDAR_TYPES[calendar_type]
  end

  # 色ラベル
  def color_label
    COLORS[color]
  end

  # Tailwind CSSの背景色クラス
  def bg_color_class
    case color
    when "purple" then "bg-purple-500"
    when "orange" then "bg-orange-500"
    when "pink" then "bg-pink-500"
    when "teal" then "bg-teal-500"
    when "indigo" then "bg-indigo-500"
    else "bg-purple-500"
    end
  end

  # Tailwind CSSのテキスト色クラス
  def text_color_class
    case color
    when "purple" then "text-purple-600"
    when "orange" then "text-orange-600"
    when "pink" then "text-pink-600"
    when "teal" then "text-teal-600"
    when "indigo" then "text-indigo-600"
    else "text-purple-600"
    end
  end
end
