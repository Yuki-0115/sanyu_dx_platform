# frozen_string_literal: true

class CreateEstimateCategories < ActiveRecord::Migration[8.0]
  def change
    create_table :estimate_categories do |t|
      t.references :estimate, null: false, foreign_key: true
      t.string :name, null: false
      t.decimal :overhead_rate, precision: 5, scale: 2, default: 0
      t.decimal :welfare_rate, precision: 5, scale: 2, default: 0
      t.integer :sort_order, default: 0

      t.timestamps
    end

    # estimate_itemsにcategory_idを追加
    add_reference :estimate_items, :estimate_category, foreign_key: true

    add_index :estimate_categories, %i[estimate_id sort_order]
  end
end
