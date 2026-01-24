# frozen_string_literal: true

class EstimateCategory < ApplicationRecord
  # Associations
  belongs_to :estimate
  has_many :estimate_items, dependent: :nullify

  # Validations
  validates :name, presence: true

  # Defaults
  attribute :overhead_rate, :decimal, default: 0
  attribute :welfare_rate, :decimal, default: 0
  attribute :sort_order, :integer, default: 0

  # 工種の直接工事費（項目の合計）
  def direct_cost
    estimate_items.sum { |item| item.amount.to_i }
  end

  # 工種の諸経費
  def overhead_cost
    (direct_cost * overhead_rate.to_d / 100).round(0)
  end

  # 工種の法定福利費
  def welfare_cost
    (direct_cost * welfare_rate.to_d / 100).round(0)
  end

  # 工種の小計（直接工事費 + 諸経費 + 法定福利費）
  def subtotal
    direct_cost + overhead_cost + welfare_cost
  end
end
