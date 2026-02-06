# frozen_string_literal: true

class CostBreakdownTemplate < ApplicationRecord
  # 原価内訳のカテゴリ
  CATEGORIES = %w[材料費 労務費 外注費 経費 その他].freeze

  # 単位の選択肢
  UNITS = %w[式 m m² m³ t kg 本 個 台 人工 日 回 箇所 セット].freeze

  # Associations
  belongs_to :employee, optional: true

  # Validations
  validates :name, presence: true
  validates :category, inclusion: { in: CATEGORIES, allow_blank: true }

  # Scopes
  scope :shared, -> { where(is_shared: true) }
  scope :by_category, ->(category) { where(category: category) if category.present? }
  scope :available_for, ->(employee) {
    where(is_shared: true).or(where(employee_id: employee.id))
  }
  scope :ordered, -> { order(:category, :sort_order, :name) }

  # Defaults
  attribute :unit, :string, default: "式"
  attribute :sort_order, :integer, default: 0
  attribute :is_shared, :boolean, default: false
end
