# frozen_string_literal: true

class CreateBaseCostTemplates < ActiveRecord::Migration[8.0]
  def change
    create_table :base_cost_templates do |t|
      t.string :category, null: false
      t.string :item_name, null: false
      t.string :unit
      t.decimal :unit_price, precision: 12, scale: 2
      t.string :supplier_name
      t.text :note
      t.integer :sort_order, default: 0

      t.timestamps
    end

    add_index :base_cost_templates, :category
  end
end
