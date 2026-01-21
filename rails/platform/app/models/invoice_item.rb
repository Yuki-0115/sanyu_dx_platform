# frozen_string_literal: true

class InvoiceItem < ApplicationRecord

  # 単位の選択肢
  UNITS = %w[式 個 本 m m² m³ kg t 台 日 人工 一式].freeze

  # Associations
  belongs_to :invoice

  # Validations
  validates :name, presence: true
  validates :quantity, numericality: { greater_than: 0 }
  validates :unit_price, numericality: { greater_than_or_equal_to: 0 }
  validates :unit, inclusion: { in: UNITS }, allow_blank: true

  # Callbacks
  before_validation :calculate_subtotal
  after_save :update_invoice_amount
  after_destroy :update_invoice_amount

  # Scopes
  default_scope { order(:position, :created_at) }

  private

  def calculate_subtotal
    self.subtotal = (quantity.to_d * unit_price.to_d).round
  end

  def update_invoice_amount
    invoice.recalculate_amount!
  end
end
