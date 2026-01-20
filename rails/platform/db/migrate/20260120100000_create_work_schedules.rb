# frozen_string_literal: true

class CreateWorkSchedules < ActiveRecord::Migration[8.0]
  def change
    create_table :work_schedules do |t|
      t.references :tenant, null: false, foreign_key: true
      t.date :scheduled_date, null: false
      t.string :shift, null: false, default: "day"
      t.references :employee, null: false, foreign_key: true
      t.string :site_name
      t.text :notes

      t.timestamps
    end

    add_index :work_schedules, [:tenant_id, :scheduled_date, :shift, :employee_id],
              unique: true, name: "idx_work_schedules_unique"
    add_index :work_schedules, [:scheduled_date, :shift]
  end
end
