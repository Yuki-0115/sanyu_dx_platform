# frozen_string_literal: true

class CompanyHoliday < ApplicationRecord
  # カレンダー種別
  CALENDAR_TYPES = {
    "worker" => "作業員用",
    "office" => "事務用"
  }.freeze

  validates :holiday_date, presence: true
  validates :calendar_type, presence: true, inclusion: { in: CALENDAR_TYPES.keys }
  validates :holiday_date, uniqueness: { scope: :calendar_type, message: "はこのカレンダーに既に登録されています" }

  scope :worker, -> { where(calendar_type: "worker") }
  scope :office, -> { where(calendar_type: "office") }
  scope :for_year, ->(year) { where(holiday_date: Date.new(year, 1, 1)..Date.new(year, 12, 31)) }
  scope :for_month, ->(date) { where(holiday_date: date.beginning_of_month..date.end_of_month) }
  scope :for_date_range, ->(range) { where(holiday_date: range) }
  scope :upcoming, -> { where("holiday_date >= ?", Date.current).order(:holiday_date) }

  # 指定日が会社休日かどうか
  def self.holiday?(date, calendar_type: nil)
    scope = where(holiday_date: date)
    scope = scope.where(calendar_type: calendar_type) if calendar_type
    scope.exists?
  end

  # 指定日の休日名を取得
  def self.holiday_name(date, calendar_type: nil)
    scope = where(holiday_date: date)
    scope = scope.where(calendar_type: calendar_type) if calendar_type
    scope.first&.name
  end

  # カレンダー種別のラベル
  def calendar_type_label
    CALENDAR_TYPES[calendar_type]
  end

  # 年間休日数をカウント
  def self.count_for_year(year, calendar_type:)
    where(calendar_type: calendar_type)
      .for_year(year)
      .count
  end
end
