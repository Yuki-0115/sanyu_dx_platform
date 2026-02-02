# frozen_string_literal: true

class AddPaymentTypeToFixedExpenseSchedules < ActiveRecord::Migration[8.0]
  def change
    # 支払日タイプ: fixed(固定), variable(変動), one_time(単発)
    add_column :fixed_expense_schedules, :payment_type, :string, default: "fixed", null: false

    # 金額タイプを明示的に（既存のis_variableをリネーム）
    rename_column :fixed_expense_schedules, :is_variable, :amount_variable

    add_index :fixed_expense_schedules, :payment_type
  end
end
