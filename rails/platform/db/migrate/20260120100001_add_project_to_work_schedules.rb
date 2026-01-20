# frozen_string_literal: true

class AddProjectToWorkSchedules < ActiveRecord::Migration[8.0]
  def change
    add_reference :work_schedules, :project, null: true, foreign_key: true

    # site_nameからproject_idへの移行用（site_nameはそのまま残す）
    # ユニーク制約を更新（employee_id → project_id + employee_id）
    remove_index :work_schedules, name: "idx_work_schedules_unique"
    add_index :work_schedules, [:tenant_id, :scheduled_date, :shift, :project_id, :employee_id],
              unique: true, name: "idx_work_schedules_unique"
  end
end
