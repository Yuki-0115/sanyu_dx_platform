# frozen_string_literal: true

class CreateEstimateConfirmations < ActiveRecord::Migration[8.0]
  def change
    create_table :estimate_confirmations do |t|
      t.references :estimate, null: false, foreign_key: true
      t.string :item_category
      t.string :item_name
      t.string :responsibility  # 'client' or 'company' or 'both' or nil
      t.text :note
      t.integer :sort_order, default: 0

      t.timestamps
    end

    add_index :estimate_confirmations, %i[estimate_id sort_order]
  end
end
