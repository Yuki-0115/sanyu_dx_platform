# frozen_string_literal: true

class FixedExpenseSchedule < ApplicationRecord
  CATEGORIES = {
    "salary" => "給与",
    "social_insurance" => "社会保険",
    "tax" => "税金",
    "rent" => "家賃",
    "lease" => "リース料",
    "insurance" => "保険",
    "vehicle" => "ガソリン・車両費",
    "phone" => "ドコモ・電話代",
    "utility" => "水道光熱費",
    "card" => "カード",
    "fees" => "手数料",
    "machine_rental" => "機械レンタル・相殺",
    "advisory_fee" => "顧問料",
    "materials" => "材料・現場経費",
    "trainee" => "実習生",
    "loan" => "貸付金",
    "expense" => "経費",
    "miscellaneous" => "雑費"
  }.freeze

  # Validations
  validates :name, presence: true
  validates :category, presence: true, inclusion: { in: CATEGORIES.keys }
  validates :payment_day, presence: true, inclusion: { in: 0..31 }
  validates :amount, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  # Scopes
  scope :active, -> { where(active: true) }
  scope :by_category, ->(cat) { where(category: cat) }

  # Calculate payment date for a given month
  # adjust_for_holiday: true の場合、土日祝日は前営業日に調整
  def payment_date_for_month(year, month, adjust_for_holiday: false)
    base = Date.new(year, month, 1)
    raw_date = if payment_day.zero?
                 base.end_of_month
               else
                 day = [payment_day, base.end_of_month.day].min
                 Date.new(year, month, day)
               end

    if adjust_for_holiday
      PaymentTerm.previous_business_day(raw_date)
    else
      raw_date
    end
  end

  def category_label
    CATEGORIES[category] || category
  end

  def payment_day_label
    payment_day.zero? ? "末日" : "#{payment_day}日"
  end

  def variable?
    is_variable?
  end

  def fixed?
    !is_variable? && amount.present?
  end
end
