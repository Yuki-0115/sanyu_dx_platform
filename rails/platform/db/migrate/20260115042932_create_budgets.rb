class CreateBudgets < ActiveRecord::Migration[8.0]
  def change
    create_table :budgets do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :project, null: false, foreign_key: true
      t.decimal :target_profit_rate
      t.decimal :material_cost
      t.decimal :outsourcing_cost
      t.decimal :labor_cost
      t.decimal :expense_cost
      t.decimal :total_cost
      t.text :notes
      t.string :status
      t.integer :confirmed_by_id
      t.datetime :confirmed_at

      t.timestamps
    end
  end
end
