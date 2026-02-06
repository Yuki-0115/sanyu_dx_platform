# frozen_string_literal: true

class AddMultiApprovalToReceivedInvoices < ActiveRecord::Migration[8.0]
  def change
    # 経理承認
    add_reference :received_invoices, :accounting_approved_by, foreign_key: { to_table: :employees }
    add_column :received_invoices, :accounting_approved_at, :datetime

    # 営業承認
    add_reference :received_invoices, :sales_approved_by, foreign_key: { to_table: :employees }
    add_column :received_invoices, :sales_approved_at, :datetime

    # 工務承認
    add_reference :received_invoices, :engineering_approved_by, foreign_key: { to_table: :employees }
    add_column :received_invoices, :engineering_approved_at, :datetime
  end
end
