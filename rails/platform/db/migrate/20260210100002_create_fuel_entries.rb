# frozen_string_literal: true

class CreateFuelEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :fuel_entries do |t|
      t.references :daily_report, null: false, foreign_key: true
      t.string :fuel_type, default: "regular"
      t.decimal :quantity, precision: 10, scale: 2
      t.decimal :amount, precision: 12, scale: 2
      t.boolean :confirmed, default: false
      t.decimal :confirmed_amount, precision: 12, scale: 2
      t.timestamps
    end
  end
end
