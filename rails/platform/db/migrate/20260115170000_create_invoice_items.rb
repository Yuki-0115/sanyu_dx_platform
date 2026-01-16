# frozen_string_literal: true

class CreateInvoiceItems < ActiveRecord::Migration[8.0]
  def change
    create_table :invoice_items do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :invoice, null: false, foreign_key: true
      t.string :name, null: false
      t.date :work_date
      t.decimal :quantity, precision: 10, scale: 2, default: 1
      t.string :unit, default: "式"
      t.decimal :unit_price, precision: 12, scale: 0, default: 0
      t.decimal :subtotal, precision: 12, scale: 0, default: 0
      t.text :description
      t.integer :position, default: 0

      t.timestamps
    end

    add_index :invoice_items, [:invoice_id, :position]
  end
end
