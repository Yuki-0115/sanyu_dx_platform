# frozen_string_literal: true

class AddExternalSiteToDailyReports < ActiveRecord::Migration[8.0]
  def change
    # 常用現場対応: 自社案件以外の現場で働く場合
    add_column :daily_reports, :is_external, :boolean, default: false, null: false
    add_column :daily_reports, :external_site_name, :string

    # project_id を nullable に変更（外部現場の場合は不要）
    change_column_null :daily_reports, :project_id, true
  end
end
