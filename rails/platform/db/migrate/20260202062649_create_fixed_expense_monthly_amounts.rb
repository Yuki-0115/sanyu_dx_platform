# frozen_string_literal: true

class CreateFixedExpenseMonthlyAmounts < ActiveRecord::Migration[8.0]
  def change
    create_table :fixed_expense_monthly_amounts do |t|
      t.references :fixed_expense_schedule, null: false, foreign_key: true
      t.integer :year, null: false
      t.integer :month, null: false
      t.decimal :amount, precision: 15, scale: 2, null: false
      t.text :notes

      t.timestamps
    end

    # 同じスケジュール・年月の組み合わせは一意
    add_index :fixed_expense_monthly_amounts,
              %i[fixed_expense_schedule_id year month],
              unique: true,
              name: "idx_fixed_expense_monthly_amounts_unique"
  end
end
