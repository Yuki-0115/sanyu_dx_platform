class ModifyDailyReportsAddCostFields < ActiveRecord::Migration[8.0]
  def change
    # Remove temperature fields
    remove_column :daily_reports, :temperature_high, :integer
    remove_column :daily_reports, :temperature_low, :integer

    # Add cost and resource fields
    add_column :daily_reports, :materials_used, :text
    add_column :daily_reports, :machines_used, :text
    add_column :daily_reports, :labor_details, :text
    add_column :daily_reports, :outsourcing_details, :text
    add_column :daily_reports, :transportation_cost, :decimal, precision: 15, scale: 2
  end
end
