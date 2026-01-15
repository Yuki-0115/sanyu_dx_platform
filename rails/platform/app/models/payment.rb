# frozen_string_literal: true

class Payment < ApplicationRecord
  include TenantScoped
  include Auditable

  # Associations
  belongs_to :invoice

  # Validations
  validates :payment_date, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }

  # Callbacks
  after_save :update_invoice_status
  after_destroy :update_invoice_status

  private

  def update_invoice_status
    return unless invoice

    if invoice.remaining_amount <= 0
      invoice.mark_as_paid!
    elsif invoice.status == "paid"
      invoice.update!(status: "waiting")
    end
  end
end
