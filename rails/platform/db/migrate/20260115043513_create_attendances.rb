class CreateAttendances < ActiveRecord::Migration[8.0]
  def change
    create_table :attendances do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :daily_report, null: false, foreign_key: true
      t.references :employee, null: false, foreign_key: true
      t.string :attendance_type, null: false
      t.time :start_time
      t.time :end_time
      t.integer :travel_distance

      t.timestamps
    end

    add_index :attendances, %i[tenant_id daily_report_id employee_id], unique: true, name: "idx_attendances_unique"
  end
end
