# frozen_string_literal: true

class Invoice < ApplicationRecord
  include TenantScoped
  include Auditable

  # Constants
  STATUSES = %w[draft issued waiting paid overdue].freeze
  TAX_RATE = 0.10  # 消費税率10%

  # Associations
  belongs_to :project
  has_many :payments, dependent: :restrict_with_error
  has_many :invoice_items, dependent: :destroy

  accepts_nested_attributes_for :invoice_items, allow_destroy: true,
                                reject_if: ->(attrs) { attrs["name"].blank? }

  # Validations
  validates :invoice_number, uniqueness: { scope: :tenant_id }, allow_blank: true
  validates :amount, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :status, inclusion: { in: STATUSES }

  # Defaults
  attribute :status, :string, default: "draft"
  attribute :amount, :decimal, default: 0
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

  # 明細から金額を再計算
  def recalculate_amount!
    new_amount = invoice_items.sum(:subtotal)
    new_tax = (new_amount * TAX_RATE).round
    update_columns(
      amount: new_amount,
      tax_amount: new_tax,
      total_amount: new_amount + new_tax
    )
  end

  # 消費税を自動計算
  def calculate_tax_from_amount
    self.tax_amount = (amount.to_d * TAX_RATE).round
  end

  private

  def calculate_total_amount
    self.total_amount = amount.to_d + tax_amount.to_d
  end
end
