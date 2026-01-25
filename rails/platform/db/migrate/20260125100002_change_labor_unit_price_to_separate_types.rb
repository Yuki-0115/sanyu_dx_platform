# frozen_string_literal: true

class ChangeLaborUnitPriceToSeparateTypes < ActiveRecord::Migration[8.0]
  def change
    # 既存のlabor_unit_priceをregular_labor_unit_priceにリネーム
    rename_column :budgets, :labor_unit_price, :regular_labor_unit_price

    # 仮社員・外注用の単価を追加
    add_column :budgets, :temporary_labor_unit_price, :decimal, precision: 10, scale: 0, default: 18000
    add_column :budgets, :outsourcing_unit_price, :decimal, precision: 10, scale: 0, default: 18000
  end
end
