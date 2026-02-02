# frozen_string_literal: true

class RenamePaymentTermsInClients < ActiveRecord::Migration[8.0]
  def change
    rename_column :clients, :payment_terms, :payment_terms_text
  end
end
