# frozen_string_literal: true

class CreateMonthlyAdminExpenses < ActiveRecord::Migration[8.0]
  def change
    create_table :monthly_admin_expenses do |t|
      t.integer :year, null: false, comment: "年"
      t.integer :month, null: false, comment: "月"
      t.string :category, null: false, comment: "カテゴリ"
      t.string :name, null: false, comment: "項目名"
      t.decimal :amount, precision: 12, scale: 0, default: 0, null: false, comment: "金額"
      t.text :description, comment: "備考"

      t.timestamps
    end

    add_index :monthly_admin_expenses, [:year, :month]
    add_index :monthly_admin_expenses, [:year, :month, :category]
  end
end
