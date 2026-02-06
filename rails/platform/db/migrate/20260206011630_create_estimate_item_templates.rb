class CreateEstimateItemTemplates < ActiveRecord::Migration[8.0]
  def change
    create_table :estimate_item_templates do |t|
      t.string :name, null: false
      t.string :category
      t.string :unit
      t.decimal :default_unit_price, precision: 12, scale: 2
      t.string :specification
      t.string :note
      t.integer :sort_order, default: 0
      t.boolean :is_shared, default: false
      t.references :employee, null: true, foreign_key: true

      t.timestamps
    end

    add_index :estimate_item_templates, :category
    add_index :estimate_item_templates, :is_shared
  end
end
