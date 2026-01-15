# frozen_string_literal: true

class AddProjectTypeToProjects < ActiveRecord::Migration[8.0]
  def change
    # 案件種別: regular(通常案件), misc(その他/小工事/常用)
    add_column :projects, :project_type, :string, default: "regular", null: false
    add_index :projects, :project_type
  end
end
