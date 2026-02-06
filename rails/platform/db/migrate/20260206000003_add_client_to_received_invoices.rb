# frozen_string_literal: true

class AddClientToReceivedInvoices < ActiveRecord::Migration[8.0]
  def change
    add_reference :received_invoices, :client, foreign_key: true
  end
end
