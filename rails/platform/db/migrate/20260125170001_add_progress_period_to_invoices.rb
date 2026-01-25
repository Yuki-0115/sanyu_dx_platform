# frozen_string_literal: true

class AddProgressPeriodToInvoices < ActiveRecord::Migration[8.0]
  def change
    add_column :invoices, :progress_year, :integer, comment: "対象年"
    add_column :invoices, :progress_month, :integer, comment: "対象月"
    add_index :invoices, [:progress_year, :progress_month]
  end
end
