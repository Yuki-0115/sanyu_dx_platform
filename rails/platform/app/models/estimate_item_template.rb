# frozen_string_literal: true

class EstimateItemTemplate < ApplicationRecord
  # カテゴリの選択肢
  CATEGORIES = %w[舗装工事 土工事 コンクリート工事 鉄筋工事 型枠工事 外構工事 解体工事 仮設工事 その他].freeze

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
