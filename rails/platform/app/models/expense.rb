# frozen_string_literal: true

class Expense < ApplicationRecord
  include TenantScoped
  include Auditable

  # Constants
  EXPENSE_TYPES = %w[site sales admin].freeze
  CATEGORIES = %w[material transport equipment rental consumable meal other].freeze
  PAYMENT_METHODS = %w[cash company_card advance credit].freeze
  STATUSES = %w[pending approved rejected].freeze

  # Associations
  belongs_to :daily_report, optional: true
  belongs_to :project, optional: true
  belongs_to :payer, class_name: "Employee", optional: true
  belongs_to :approved_by, class_name: "Employee", optional: true

  # 領収書・伝票添付
  has_one_attached :receipt
  has_one_attached :voucher

  # Validations
  validates :expense_type, presence: true, inclusion: { in: EXPENSE_TYPES }
  validates :category, presence: true, inclusion: { in: CATEGORIES }
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :payment_method, inclusion: { in: PAYMENT_METHODS }, allow_blank: true
  validates :status, inclusion: { in: STATUSES }

  # Defaults
  attribute :status, :string, default: "pending"

  # Scopes
  scope :pending, -> { where(status: "pending") }
  scope :approved, -> { where(status: "approved") }
  scope :site_expenses, -> { where(expense_type: "site") }

  # Instance methods
  def approve!(user)
    update!(status: "approved", approved_by: user, approved_at: Time.current)
  end

  def reject!(user)
    update!(status: "rejected", approved_by: user, approved_at: Time.current)
  end
end
