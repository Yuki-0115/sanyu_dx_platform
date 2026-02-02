# frozen_string_literal: true

class CashFlowEntry < ApplicationRecord
  include Auditable

  # Constants
  ENTRY_TYPES = %w[income expense].freeze
  INCOME_CATEGORIES = %w[receivable other_income].freeze
  EXPENSE_CATEGORIES = %w[outsourcing salary social_insurance lease insurance rent utility other_expense].freeze
  STATUSES = %w[expected confirmed completed cancelled].freeze

  CATEGORY_LABELS = {
    # Income
    "receivable" => "売掛金入金",
    "other_income" => "その他入金",
    # Expense
    "outsourcing" => "外注費",
    "salary" => "給与",
    "social_insurance" => "社会保険料",
    "lease" => "リース料",
    "insurance" => "保険料",
    "rent" => "家賃",
    "utility" => "水道光熱費",
    "other_expense" => "その他"
  }.freeze

  STATUS_LABELS = {
    "expected" => "予定",
    "confirmed" => "確認済",
    "completed" => "完了",
    "cancelled" => "取消"
  }.freeze

  # Associations
  belongs_to :source, polymorphic: true, optional: true
  belongs_to :client, optional: true
  belongs_to :partner, optional: true
  belongs_to :project, optional: true
  belongs_to :confirmed_by, class_name: "Employee", optional: true

  # Validations
  validates :entry_type, presence: true, inclusion: { in: ENTRY_TYPES }
  validates :category, presence: true
  validates :base_date, presence: true
  validates :expected_date, presence: true
  validates :expected_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :status, inclusion: { in: STATUSES }

  # Defaults
  attribute :status, :string, default: "expected"
  attribute :adjustment_amount, :decimal, default: 0

  # Scopes
  scope :income, -> { where(entry_type: "income") }
  scope :expense, -> { where(entry_type: "expense") }
  scope :for_date, ->(date) { where(expected_date: date) }
  scope :for_date_range, ->(range) { where(expected_date: range) }
  scope :expected, -> { where(status: "expected") }
  scope :confirmed, -> { where(status: "confirmed") }
  scope :completed, -> { where(status: "completed") }
  scope :pending, -> { where(status: %w[expected confirmed]) }

  # Instance methods
  def confirm!(user, amount: nil, date: nil, notes: nil)
    update!(
      status: "confirmed",
      confirmed_by: user,
      confirmed_at: Time.current,
      actual_amount: amount || expected_amount,
      expected_date: date || expected_date,
      manual_override: date.present? || amount.present?,
      notes: notes
    )
  end

  def complete!(actual_date, actual_amount = nil)
    update!(
      status: "completed",
      actual_date: actual_date,
      actual_amount: actual_amount || self.actual_amount || expected_amount
    )
  end

  def cancel!
    update!(status: "cancelled")
  end

  def net_amount
    (actual_amount || expected_amount).to_d - adjustment_amount.to_d
  end

  def display_amount
    actual_amount || expected_amount
  end

  def income?
    entry_type == "income"
  end

  def expense?
    entry_type == "expense"
  end

  def category_label
    CATEGORY_LABELS[category] || category
  end

  def status_label
    STATUS_LABELS[status] || status
  end

  def entity_name
    if income?
      client&.name || project&.client&.name || "-"
    else
      partner&.name || "-"
    end
  end
end
