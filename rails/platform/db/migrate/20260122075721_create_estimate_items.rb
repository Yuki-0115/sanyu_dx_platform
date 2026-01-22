# frozen_string_literal: true

class CreateEstimateItems < ActiveRecord::Migration[8.0]
  def change
    create_table :estimate_items do |t|
      t.references :estimate, null: false, foreign_key: true
      t.string :name
      t.string :specification
      t.decimal :quantity, precision: 15, scale: 4
      t.string :unit
      t.decimal :unit_price, precision: 15, scale: 2
      t.decimal :amount, precision: 15, scale: 2
      t.text :note
      t.decimal :budget_quantity, precision: 15, scale: 4
      t.string :budget_unit
      t.decimal :budget_unit_price, precision: 15, scale: 2
      t.decimal :budget_amount, precision: 15, scale: 2
      t.integer :construction_days
      t.integer :sort_order, default: 0
      t.string :category

      t.timestamps
    end

    add_index :estimate_items, %i[estimate_id sort_order]
  end
end
