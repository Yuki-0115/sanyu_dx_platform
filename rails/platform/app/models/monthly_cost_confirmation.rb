# frozen_string_literal: true

# 月次費用確認ステータス
# 材料費・経費など、日報金額をそのまま使用するが確認済みかどうかを管理
class MonthlyCostConfirmation < ApplicationRecord
  COST_TYPES = %w[material expense].freeze
  COST_TYPE_LABELS = {
    "material" => "材料費",
    "expense" => "経費"
  }.freeze

  belongs_to :confirmed_by, class_name: "Employee", optional: true

  validates :year, presence: true, numericality: { only_integer: true, greater_than: 2000 }
  validates :month, presence: true, numericality: { only_integer: true, in: 1..12 }
  validates :cost_type, presence: true, inclusion: { in: COST_TYPES }
  validates :cost_type, uniqueness: { scope: [:year, :month], message: "この月の確認は既に登録されています" }

  scope :for_month, ->(year, month) { where(year: year, month: month) }

  def self.confirmed?(year, month, cost_type)
    for_month(year, month).exists?(cost_type: cost_type)
  end

  def self.material_confirmed?(year, month)
    confirmed?(year, month, "material")
  end

  def self.expense_confirmed?(year, month)
    confirmed?(year, month, "expense")
  end

  def self.confirm!(year, month, cost_type, employee = nil)
    find_or_create_by!(year: year, month: month, cost_type: cost_type) do |c|
      c.confirmed_by = employee
      c.confirmed_at = Time.current
    end
  end

  def self.unconfirm!(year, month, cost_type)
    for_month(year, month).where(cost_type: cost_type).destroy_all
  end

  def cost_type_label
    COST_TYPE_LABELS[cost_type] || cost_type
  end
end
