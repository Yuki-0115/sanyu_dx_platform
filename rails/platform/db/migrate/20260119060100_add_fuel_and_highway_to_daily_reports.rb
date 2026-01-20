# frozen_string_literal: true

class AddFuelAndHighwayToDailyReports < ActiveRecord::Migration[8.0]
  def change
    # 燃料費（ガソリンカード精算）
    add_column :daily_reports, :fuel_quantity, :decimal, precision: 10, scale: 2  # 給油量（L）
    add_column :daily_reports, :fuel_amount, :decimal, precision: 12, scale: 2    # 仮金額
    add_column :daily_reports, :fuel_confirmed, :boolean, default: false          # 確定済みフラグ
    add_column :daily_reports, :fuel_confirmed_amount, :decimal, precision: 12, scale: 2  # 確定金額

    # 高速代（ETCカード精算）
    add_column :daily_reports, :highway_count, :integer                           # 利用回数
    add_column :daily_reports, :highway_amount, :decimal, precision: 12, scale: 2 # 仮金額
    add_column :daily_reports, :highway_route, :string                            # 区間メモ
    add_column :daily_reports, :highway_confirmed, :boolean, default: false       # 確定済みフラグ
    add_column :daily_reports, :highway_confirmed_amount, :decimal, precision: 12, scale: 2  # 確定金額
  end
end
