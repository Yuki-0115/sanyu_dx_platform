class AddSalaryFieldsToEmployees < ActiveRecord::Migration[8.0]
  def change
    add_column :employees, :monthly_salary, :decimal, precision: 12, scale: 0, default: 0
    add_column :employees, :social_insurance_monthly, :decimal, precision: 12, scale: 0, default: 0
    add_column :employees, :daily_rate, :decimal, precision: 10, scale: 0, default: 0
  end
end
