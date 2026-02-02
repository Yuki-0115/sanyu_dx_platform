# frozen_string_literal: true

class FixedExpenseSchedule < ApplicationRecord
  CATEGORIES = {
    "salary" => "給与",
    "social_insurance" => "社会保険料",
    "lease" => "リース料",
    "insurance" => "保険料",
    "rent" => "家賃",
    "utility" => "水道光熱費",
    "other" => "その他"
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
  def payment_date_for_month(year, month)
    base = Date.new(year, month, 1)
    if payment_day.zero?
      base.end_of_month
    else
      day = [payment_day, base.end_of_month.day].min
      Date.new(year, month, day)
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
