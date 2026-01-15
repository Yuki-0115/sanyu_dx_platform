# frozen_string_literal: true

class Invoice < ApplicationRecord
  include TenantScoped
  include Auditable

  # Constants
  STATUSES = %w[draft issued waiting paid overdue].freeze

  # Associations
  belongs_to :project
  has_many :payments, dependent: :restrict_with_error

  # Validations
  validates :invoice_number, uniqueness: { scope: :tenant_id }, allow_blank: true
  validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :status, inclusion: { in: STATUSES }

  # Defaults
  attribute :status, :string, default: "draft"
  attribute :tax_amount, :decimal, default: 0
  attribute :total_amount, :decimal, default: 0

  # Callbacks
  before_save :calculate_total_amount

  # Scopes
  scope :unpaid, -> { where.not(status: "paid") }
  scope :overdue, -> { where(status: "overdue") }

  # Instance methods
  def issue!
    update!(status: "issued", issued_date: Time.current.to_date)
  end

  def mark_as_paid!
    update!(status: "paid")
  end

  def paid_amount
    payments.sum(:amount)
  end

  def remaining_amount
    total_amount.to_d - paid_amount
  end

  private

  def calculate_total_amount
    self.total_amount = amount.to_d + tax_amount.to_d
  end
end
