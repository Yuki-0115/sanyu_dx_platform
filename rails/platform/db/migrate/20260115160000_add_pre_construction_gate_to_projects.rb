class AddPreConstructionGateToProjects < ActiveRecord::Migration[8.0]
  def change
    # 着工前ゲート（5点チェック）
    add_column :projects, :site_conditions_checked, :boolean, default: false
    add_column :projects, :night_work_checked, :boolean, default: false
    add_column :projects, :regulations_checked, :boolean, default: false
    add_column :projects, :safety_docs_checked, :boolean, default: false
    add_column :projects, :delivery_checked, :boolean, default: false
    add_column :projects, :pre_construction_gate_completed_at, :datetime
  end
end
