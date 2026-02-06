class CreateCostBreakdownTemplates < ActiveRecord::Migration[8.0]
  def change
    create_table :cost_breakdown_templates do |t|
      t.string :name, null: false
      t.string :category # 材料費、労務費、外注費、経費など
      t.string :unit, default: "式"
      t.decimal :default_unit_price, precision: 15, scale: 2
      t.text :note
      t.integer :sort_order, default: 0
      t.boolean :is_shared, default: false
      t.references :employee, null: true, foreign_key: true

      t.timestamps
    end

    add_index :cost_breakdown_templates, :category
    add_index :cost_breakdown_templates, :is_shared
  end
end
