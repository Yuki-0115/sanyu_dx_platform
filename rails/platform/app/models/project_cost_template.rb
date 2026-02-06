# frozen_string_literal: true

# 案件別単価テンプレート
# 営業・工務があらかじめ設定し、職長が日報入力時に参照する
class ProjectCostTemplate < ApplicationRecord
  belongs_to :project

  CATEGORIES = %w[material outsourcing machinery other].freeze
  CATEGORY_LABELS = {
    "material" => "材料費",
    "outsourcing" => "外注費",
    "machinery" => "機械費",
    "other" => "その他"
  }.freeze

  validates :category, presence: true, inclusion: { in: CATEGORIES }
  validates :item_name, presence: true
  validates :unit_price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  scope :ordered, -> { order(:category, :sort_order, :item_name) }
  scope :by_category, ->(cat) { where(category: cat) }

  def category_label
    CATEGORY_LABELS[category] || category
  end

  def formatted_unit_price
    return "-" if unit_price.blank?
    "#{unit_price.to_i.to_fs(:delimited)}円"
  end

  def formatted_unit_price_with_unit
    return "-" if unit_price.blank?
    unit_str = unit.presence || "式"
    "#{unit_price.to_i.to_fs(:delimited)}円/#{unit_str}"
  end
end
