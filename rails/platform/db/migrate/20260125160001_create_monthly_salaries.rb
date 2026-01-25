class CreateMonthlySalaries < ActiveRecord::Migration[8.0]
  def change
    create_table :monthly_salaries do |t|
      t.references :employee, null: false, foreign_key: true
      t.integer :year, null: false
      t.integer :month, null: false
      t.decimal :total_amount, precision: 15, scale: 0, null: false, default: 0
      t.text :note
      t.timestamps
    end

    add_index :monthly_salaries, [:year, :month]
    add_index :monthly_salaries, [:employee_id, :year, :month], unique: true
  end
end
