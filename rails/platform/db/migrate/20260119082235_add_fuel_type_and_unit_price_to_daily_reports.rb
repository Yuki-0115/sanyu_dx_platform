class AddFuelTypeAndUnitPriceToDailyReports < ActiveRecord::Migration[8.0]
  def change
    add_column :daily_reports, :fuel_type, :string, default: "regular"
    add_column :daily_reports, :fuel_unit_price, :decimal, precision: 10, scale: 2
  end
end
