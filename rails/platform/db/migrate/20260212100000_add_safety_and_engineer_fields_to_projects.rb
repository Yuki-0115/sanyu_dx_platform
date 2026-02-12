# frozen_string_literal: true

class AddSafetyAndEngineerFieldsToProjects < ActiveRecord::Migration[8.0]
  def change
    # 区分（一次/二次/三次）
    add_column :projects, :contract_tier, :string, default: "first"

    # 専任/非専任
    add_column :projects, :engineer_type, :string, default: "non_exclusive"

    # 主任技術者
    add_reference :projects, :chief_engineer, foreign_key: { to_table: :employees }, null: true

    # 現場代理人
    add_reference :projects, :site_agent, foreign_key: { to_table: :employees }, null: true

    # 安全書類ステータス
    add_column :projects, :safety_doc_status, :string, default: "not_submitted"

    # 安全書類提出方法
    add_column :projects, :safety_doc_method, :string, null: true

    # インデックス
    add_index :projects, :contract_tier
    add_index :projects, :safety_doc_status
  end
end
