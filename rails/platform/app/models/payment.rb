# frozen_string_literal: true

class Payment < ApplicationRecord
  include Auditable

  # Associations
  belongs_to :invoice

  # Validations
  validates :payment_date, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }

  # Callbacks
  after_save :update_invoice_status
  after_destroy :update_invoice_status
  after_create_commit :notify_payment_received

  private

  def update_invoice_status
    return unless invoice

    if invoice.remaining_amount <= 0
      invoice.mark_as_paid!
    elsif invoice.status == "paid"
      invoice.update!(status: "waiting")
    end
  end

  def notify_payment_received
    NotificationJob.perform_later(
      event_type: "payment_received",
      record_type: "Payment",
      record_id: id
    )
  end
end
