# frozen_string_literal: true

class CreateFixedExpenseSchedules < ActiveRecord::Migration[8.0]
  def change
    create_table :fixed_expense_schedules do |t|
      t.string :name, null: false                    # "給与支給"
      t.string :category, null: false                # salary, social_insurance, lease, insurance, rent, other
      t.integer :payment_day, null: false            # 支払日 (1-31, 0=末日)
      t.decimal :amount, precision: 15, scale: 2     # 固定金額（変動の場合はnil）
      t.boolean :is_variable, default: false         # 毎月金額変動あり
      t.boolean :active, default: true
      t.text :notes

      t.timestamps
    end

    add_index :fixed_expense_schedules, :category
    add_index :fixed_expense_schedules, :active
  end
end
