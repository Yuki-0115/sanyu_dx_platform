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

  # 原価内訳の合計（これが予算金額になる）
  # 保存時は未保存のレコードも含めて計算
  def cost_breakdown_total
    if estimate_item_costs.loaded?
      # メモリ上で計算（新規・更新時）
      estimate_item_costs.reject(&:marked_for_destruction?).sum do |cost|
        (cost.quantity.to_d * cost.unit_price.to_d).round(0)
      end
    else
      # DBから取得（表示時）
      estimate_item_costs.sum(:amount) || 0
    end
  end

  # 原価内訳から予算単価を計算（表示用）
  def calculated_budget_unit_price
    qty = budget_quantity_or_default.to_d
    return 0 if qty.zero?
    (cost_breakdown_total / qty).round(0)
  end

  # 内訳があるかどうか
  def has_cost_breakdown?
    if estimate_item_costs.loaded?
      estimate_item_costs.reject(&:marked_for_destruction?).any?
    else
      estimate_item_costs.exists?
    end
  end

  private

  def calculate_amounts
    # 見積金額
    self.amount = (quantity.to_d * unit_price.to_d).round(0) if quantity.present? && unit_price.present?

    # 予算金額：内訳があればその合計、なければ従来通り
    if has_cost_breakdown?
      self.budget_amount = cost_breakdown_total
      # 予算単価も自動計算（表示用に保持）
      qty = budget_quantity.presence || quantity
      self.budget_unit_price = calculated_budget_unit_price if qty.to_d > 0
    else
      # 内訳がない場合は従来通り
      qty = budget_quantity.presence || quantity
      price = budget_unit_price
      self.budget_amount = (qty.to_d * price.to_d).round(0) if qty.present? && price.present?
    end
  end
end
