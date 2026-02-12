# frozen_string_literal: true

class CreateHighwayEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :highway_entries do |t|
      t.references :daily_report, null: false, foreign_key: true
      t.integer :count, default: 1
      t.decimal :amount, precision: 12, scale: 2
      t.string :route
      t.boolean :confirmed, default: false
      t.decimal :confirmed_amount, precision: 12, scale: 2
      t.timestamps
    end
  end
end
