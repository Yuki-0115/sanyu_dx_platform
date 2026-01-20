# frozen_string_literal: true

class AddShiftToProjectAssignments < ActiveRecord::Migration[8.0]
  def change
    add_column :project_assignments, :shift, :string, default: "day", null: false

    # 既存のユニーク制約を削除して、shift を含む新しい制約を追加
    # （同じ社員が同じ案件に日勤・夜勤で別々に配置可能にする）
    remove_index :project_assignments, name: "idx_project_assignments_unique"
    add_index :project_assignments, [:tenant_id, :employee_id, :project_id, :shift], unique: true, name: "idx_project_assignments_unique"
  end
end
