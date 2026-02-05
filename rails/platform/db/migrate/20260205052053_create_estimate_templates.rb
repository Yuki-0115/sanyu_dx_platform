class CreateEstimateTemplates < ActiveRecord::Migration[8.0]
  def change
    create_table :estimate_templates do |t|
      t.string :template_type, null: false
      t.string :name, null: false
      t.text :content
      t.boolean :is_shared, default: false, null: false
      t.references :employee, null: true, foreign_key: true
      t.integer :sort_order, default: 0

      t.timestamps
    end

    add_index :estimate_templates, [:template_type, :is_shared]
    add_index :estimate_templates, [:template_type, :employee_id]
  end
end
