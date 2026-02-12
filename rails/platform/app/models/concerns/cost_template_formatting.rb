# frozen_string_literal: true

# 原価テンプレートの共通フォーマットメソッド
# BaseCostTemplate / ProjectCostTemplate で共有
module CostTemplateFormatting
  extend ActiveSupport::Concern

  UNITS = %w[式 m m² m³ t kg 本 個 台 人工 日 回 箇所 セット].freeze

  def category_label
    self.class::CATEGORY_LABELS[category] || category
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
