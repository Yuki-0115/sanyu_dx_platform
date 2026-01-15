# frozen_string_literal: true

class AddCostFieldsToDailyReports < ActiveRecord::Migration[8.0]
  def change
    # 原価金額フィールド（テキストフィールドとは別に金額を管理）
    add_column :daily_reports, :labor_cost, :decimal, precision: 15, scale: 2, default: 0
    add_column :daily_reports, :material_cost, :decimal, precision: 15, scale: 2, default: 0
    add_column :daily_reports, :outsourcing_cost, :decimal, precision: 15, scale: 2, default: 0
    # transportation_cost は既存
  end
end
