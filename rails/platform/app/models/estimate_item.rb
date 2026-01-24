# frozen_string_literal: true

class EstimateItem < ApplicationRecord
  # Associations
  belongs_to :estimate
  belongs_to :estimate_category, optional: true
  has_many :estimate_item_costs, dependent: :destroy

  accepts_nested_attributes_for :estimate_item_costs, allow_destroy: true,
                                reject_if: ->(attrs) { attrs["cost_name"].blank? }

  # Validations
  validates :name, presence: true

  # Defaults
  attribute :sort_order, :integer, default: 0

  # Callbacks
  before_save :calculate_amounts

  # 予算数量・単位は見積と同じ値をデフォルトで使用
  def budget_quantity_or_default
    budget_quantity.presence || quantity
  end

  def budget_unit_or_default
    budget_unit.presence || unit
  end

  # 原価内訳の合計
  def cost_breakdown_total
    estimate_item_costs.sum(:amount) || 0
  end

  # 原価内訳から予算単価を計算
  def calculate_budget_unit_price_from_costs
    return 0 if budget_quantity_or_default.to_d.zero?
    (cost_breakdown_total / budget_quantity_or_default.to_d).round(2)
  end

  private

  def calculate_amounts
    # 見積金額
    self.amount = (quantity.to_d * unit_price.to_d).round(0) if quantity.present? && unit_price.present?

    # 予算金額
    qty = budget_quantity.presence || quantity
    price = budget_unit_price
    self.budget_amount = (qty.to_d * price.to_d).round(0) if qty.present? && price.present?
  end
end
