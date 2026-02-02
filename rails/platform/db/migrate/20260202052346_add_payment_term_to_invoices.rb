# frozen_string_literal: true

class AddPaymentTermToInvoices < ActiveRecord::Migration[8.0]
  def change
    add_reference :invoices, :payment_term, foreign_key: true
    add_column :invoices, :expected_payment_date, :date
  end
end
