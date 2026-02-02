class AddOneTimeDateToFixedExpenseSchedules < ActiveRecord::Migration[8.0]
  def change
    add_column :fixed_expense_schedules, :one_time_year, :integer
    add_column :fixed_expense_schedules, :one_time_month, :integer
  end
end
