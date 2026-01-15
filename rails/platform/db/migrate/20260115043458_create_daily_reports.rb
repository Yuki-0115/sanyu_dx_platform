class CreateDailyReports < ActiveRecord::Migration[8.0]
  def change
    create_table :daily_reports do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :project, null: false, foreign_key: true
      t.references :foreman, null: false, foreign_key: { to_table: :employees }
      t.date :report_date, null: false
      t.string :weather
      t.integer :temperature_high
      t.integer :temperature_low
      t.text :work_content
      t.text :notes
      t.string :status, default: "draft"
      t.datetime :confirmed_at

      t.timestamps
    end

    add_index :daily_reports, %i[tenant_id project_id report_date], unique: true
  end
end
