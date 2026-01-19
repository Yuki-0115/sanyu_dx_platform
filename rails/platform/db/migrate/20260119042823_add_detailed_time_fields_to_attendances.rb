# frozen_string_literal: true

class AddDetailedTimeFieldsToAttendances < ActiveRecord::Migration[8.0]
  def change
    # 休憩時間（分単位）
    add_column :attendances, :break_minutes, :integer, default: 60

    # 残業時間（分単位）
    add_column :attendances, :overtime_minutes, :integer, default: 0

    # 深夜時間（分単位）- 22:00-5:00
    add_column :attendances, :night_minutes, :integer, default: 0

    # 移動時間（分単位）
    add_column :attendances, :travel_minutes, :integer, default: 0

    # 区分の詳細（出勤/公休/有給/欠勤/振休など）
    add_column :attendances, :work_category, :string, default: "work"

    # 現場メモ（現場名や作業内容など）
    add_column :attendances, :site_note, :string
  end
end
