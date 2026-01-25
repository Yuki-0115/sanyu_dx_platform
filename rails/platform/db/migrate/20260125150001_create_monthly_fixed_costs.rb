class CreateMonthlyFixedCosts < ActiveRecord::Migration[8.0]
  def change
    create_table :monthly_fixed_costs do |t|
      t.integer :year, null: false
      t.integer :month, null: false
      t.string :name, null: false
      t.string :category, null: false, default: "other"
      t.decimal :amount, precision: 15, scale: 0, null: false, default: 0
      t.text :description
      t.timestamps
    end

    add_index :monthly_fixed_costs, [:year, :month]
    add_index :monthly_fixed_costs, [:year, :month, :category]
  end
end
