# frozen_string_literal: true

class CreateOutsourcingSchedules < ActiveRecord::Migration[8.0]
  def change
    create_table :outsourcing_schedules do |t|
      t.date :scheduled_date, null: false
      t.string :shift, null: false, default: "day"  # day, night
      t.references :project, null: false, foreign_key: true
      t.references :partner, null: false, foreign_key: true
      t.integer :headcount, default: 1  # 人工（人数）
      t.string :billing_type, null: false, default: "man_days"  # man_days（人工）, contract（請負）
      t.string :notes  # 備考

      t.timestamps
    end

    add_index :outsourcing_schedules, %i[scheduled_date project_id partner_id shift],
              unique: true, name: "idx_outsourcing_schedules_unique"
  end
end
