# frozen_string_literal: true

class Estimate < ApplicationRecord
  include Auditable

  # Constants
  STATUSES = %w[draft submitted approved rejected].freeze

  # Associations
  belongs_to :project
  belongs_to :created_by, class_name: "Employee", optional: true

  has_many :estimate_items, dependent: :destroy
  has_many :estimate_confirmations, dependent: :destroy

  accepts_nested_attributes_for :estimate_items, allow_destroy: true,
                                reject_if: ->(attrs) { attrs["name"].blank? }
  accepts_nested_attributes_for :estimate_confirmations, allow_destroy: true

  # Validations
  validates :status, inclusion: { in: STATUSES }
  validates :estimate_number, uniqueness: true, allow_blank: true

  # Defaults
  attribute :status, :string, default: "draft"
  attribute :overhead_rate, :decimal, default: 4.0
  attribute :welfare_rate, :decimal, default: 3.0
  attribute :adjustment, :integer, default: 0
  attribute :validity_period, :string, default: "3ヵ月"
  attribute :version, :integer, default: 1

  # Callbacks
  before_create :generate_estimate_number

  # Scopes
  scope :approved, -> { where(status: "approved") }

  # 見積金額の小計（内訳明細の合計）
  def direct_cost
    estimate_items.sum(:amount) || 0
  end

  # 諸経費
  def overhead_cost
    (direct_cost * (overhead_rate || 0) / 100).round(0)
  end

  # 法定福利費
  def welfare_cost
    (direct_cost * (welfare_rate || 0) / 100).round(0)
  end

  # 見積合計（税抜）
  def subtotal
    direct_cost + overhead_cost + welfare_cost + (adjustment || 0)
  end

  # 消費税
  def tax_amount
    (subtotal * 0.1).round(0)
  end

  # 見積合計（税込）
  def total_amount
    subtotal + tax_amount
  end

  # 予算小計
  def budget_total
    estimate_items.sum(:budget_amount) || 0
  end

  # 粗利
  def gross_profit
    subtotal - budget_total
  end

  # 粗利率
  def profit_rate
    return 0 if subtotal.zero?
    (gross_profit.to_f / subtotal * 100).round(1)
  end

  def approved?
    status == "approved"
  end

  def can_import_to_budget?
    approved? || status == "submitted"
  end

  private

  def generate_estimate_number
    return if estimate_number.present?

    prefix = "EST"
    date_part = Date.current.strftime("%Y%m")
    seq = Estimate.where("estimate_number LIKE ?", "#{prefix}#{date_part}%").count + 1
    self.estimate_number = "#{prefix}#{date_part}#{seq.to_s.rjust(3, '0')}"
  end
end
