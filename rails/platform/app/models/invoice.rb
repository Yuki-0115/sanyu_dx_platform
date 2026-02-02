# frozen_string_literal: true

class Invoice < ApplicationRecord
  include Auditable

  # Constants
  STATUSES = %w[draft issued waiting paid overdue].freeze
  TAX_RATE = 0.10  # 消費税率10%

  # Associations
  belongs_to :project
  belongs_to :payment_term, optional: true
  has_many :payments, dependent: :restrict_with_error
  has_many :invoice_items, dependent: :destroy
  has_one :cash_flow_entry, as: :source, dependent: :destroy

  accepts_nested_attributes_for :invoice_items, allow_destroy: true,
                                reject_if: ->(attrs) { attrs["name"].blank? }

  # Validations
  validates :invoice_number, uniqueness: true, allow_blank: true
  validates :amount, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :status, inclusion: { in: STATUSES }

  # Defaults
  attribute :status, :string, default: "draft"
  attribute :amount, :decimal, default: 0
  attribute :tax_amount, :decimal, default: 0
  attribute :total_amount, :decimal, default: 0

  # Callbacks
  before_save :calculate_total_amount
  after_save :create_or_update_cash_flow_entry, if: :should_update_cash_flow?

  # Scopes
  scope :unpaid, -> { where.not(status: "paid") }
  scope :overdue, -> { where(status: "overdue") }

  # Instance methods
  def issue!
    update!(status: "issued", issued_date: Time.current.to_date)
    notify_issued
    # 案件ステータスは変更しない（複数回請求があるため）
    # 完工時に手動で status を変更する
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

  def notify_issued
    NotificationJob.perform_later(
      event_type: "invoice_issued",
      record_type: "Invoice",
      record_id: id
    )
  end

  def should_update_cash_flow?
    saved_change_to_status? || saved_change_to_total_amount? || saved_change_to_issued_date?
  end

  def create_or_update_cash_flow_entry
    return unless status.in?(%w[issued waiting])

    client = project&.client
    term = payment_term || client&.default_payment_term
    calc_expected_date = term&.calculate_payment_date(issued_date || Date.current) || due_date || (Date.current + 1.month)

    # expected_payment_dateを更新
    update_column(:expected_payment_date, calc_expected_date) if expected_payment_date != calc_expected_date

    entry = cash_flow_entry || build_cash_flow_entry
    entry.update!(
      entry_type: "income",
      category: "receivable",
      client: client,
      project: project,
      base_date: issued_date || Date.current,
      expected_date: calc_expected_date,
      expected_amount: total_amount
    )
  end
end
