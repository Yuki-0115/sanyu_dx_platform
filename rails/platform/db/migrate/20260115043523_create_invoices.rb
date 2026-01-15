class CreateInvoices < ActiveRecord::Migration[8.0]
  def change
    create_table :invoices do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :project, null: false, foreign_key: true
      t.string :invoice_number
      t.decimal :amount, precision: 15, scale: 2, null: false
      t.decimal :tax_amount, precision: 15, scale: 2, default: 0
      t.decimal :total_amount, precision: 15, scale: 2, default: 0
      t.date :issued_date
      t.date :due_date
      t.string :status, default: "draft"

      t.timestamps
    end

    add_index :invoices, %i[tenant_id invoice_number], unique: true
    add_index :invoices, :status
  end
end
