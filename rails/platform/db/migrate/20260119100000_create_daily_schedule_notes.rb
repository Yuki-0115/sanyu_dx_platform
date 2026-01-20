# frozen_string_literal: true

class CreateDailyScheduleNotes < ActiveRecord::Migration[8.0]
  def change
    create_table :daily_schedule_notes do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :project, null: false, foreign_key: true
      t.date :scheduled_date, null: false
      t.text :work_content       # 作業内容
      t.text :vehicles           # 車両
      t.text :equipment          # 機材
      t.text :heavy_equipment_transport  # 重機回送
      t.text :notes              # 連絡事項

      t.timestamps
    end

    add_index :daily_schedule_notes, [:tenant_id, :project_id, :scheduled_date], unique: true, name: 'idx_schedule_notes_unique'
  end
end
