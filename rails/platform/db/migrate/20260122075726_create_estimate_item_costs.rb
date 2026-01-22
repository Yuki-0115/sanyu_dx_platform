# frozen_string_literal: true

class CreateEstimateItemCosts < ActiveRecord::Migration[8.0]
  def change
    create_table :estimate_item_costs do |t|
      t.references :estimate_item, null: false, foreign_key: true
      t.string :cost_name
      t.decimal :quantity, precision: 15, scale: 4
      t.string :unit
      t.decimal :unit_price, precision: 15, scale: 2
      t.decimal :amount, precision: 15, scale: 2
      t.string :calculation_type
      t.jsonb :formula_params, default: {}
      t.text :note
      t.integer :sort_order, default: 0

      t.timestamps
    end

    add_index :estimate_item_costs, %i[estimate_item_id sort_order]
  end
end
