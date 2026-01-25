# frozen_string_literal: true

class AddLaborUnitPriceToBudgets < ActiveRecord::Migration[8.0]
  def change
    add_column :budgets, :labor_unit_price, :decimal, precision: 10, scale: 0, default: 18000
  end
end
