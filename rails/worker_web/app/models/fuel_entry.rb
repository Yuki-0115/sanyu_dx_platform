# frozen_string_literal: true

class FuelEntry < ApplicationRecord
  FUEL_TYPES = %w[regular high_octane diesel].freeze
  FUEL_TYPE_LABELS = { "regular" => "レギュラー", "high_octane" => "ハイオク", "diesel" => "軽油" }.freeze

  belongs_to :daily_report
  has_one_attached :receipt

  validates :fuel_type, inclusion: { in: FUEL_TYPES }, allow_blank: true
  validates :amount, numericality: { greater_than: 0 }, allow_nil: true
end
