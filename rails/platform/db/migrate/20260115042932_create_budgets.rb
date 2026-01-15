class CreateBudgets < ActiveRecord::Migration[8.0]
  def change
    create_table :budgets do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :project, null: false, foreign_key: true
      t.decimal :target_profit_rate, precision: 5, scale: 2
      t.decimal :material_cost, precision: 15, scale: 2, default: 0
      t.decimal :outsourcing_cost, precision: 15, scale: 2, default: 0
      t.decimal :labor_cost, precision: 15, scale: 2, default: 0
      t.decimal :expense_cost, precision: 15, scale: 2, default: 0
      t.decimal :total_cost, precision: 15, scale: 2, default: 0
      t.text :notes
      t.string :status, default: "draft"
      t.integer :confirmed_by_id
      t.datetime :confirmed_at

      t.timestamps
    end

    add_index :budgets, %i[tenant_id project_id], unique: true
    add_index :budgets, :confirmed_by_id
  end
end
