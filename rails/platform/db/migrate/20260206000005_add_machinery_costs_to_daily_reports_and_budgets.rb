# frozen_string_literal: true

class AddMachineryCostsToDailyReportsAndBudgets < ActiveRecord::Migration[8.0]
  def change
    # 日報に機械費カラム追加
    add_column :daily_reports, :machinery_own_cost, :decimal, precision: 12, scale: 0, default: 0
    add_column :daily_reports, :machinery_rental_cost, :decimal, precision: 12, scale: 0, default: 0

    # 予算に機械費カラム追加
    add_column :budgets, :machinery_own_cost, :decimal, precision: 12, scale: 0, default: 0
    add_column :budgets, :machinery_rental_cost, :decimal, precision: 12, scale: 0, default: 0
  end
end
