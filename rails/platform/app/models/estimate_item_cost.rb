# frozen_string_literal: true

class EstimateItemCost < ApplicationRecord
  # Associations
  belongs_to :estimate_item

  # Validations
  validates :cost_name, presence: true

  # Defaults
  attribute :sort_order, :integer, default: 0
  attribute :formula_params, :jsonb, default: {}

  # Callbacks
  before_save :calculate_amount

  # 計算タイプ
  # - manual: 手入力
  # - formula: 計算式（施工数量 × 厚さ × 配合量 ÷ 1000 など）
  CALCULATION_TYPES = %w[manual formula].freeze

  private

  def calculate_amount
    self.amount = (quantity.to_d * unit_price.to_d).round(0) if quantity.present? && unit_price.present?
  end
end
