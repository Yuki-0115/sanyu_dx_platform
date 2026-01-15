# frozen_string_literal: true

class AddRevisionFieldsToDailyReports < ActiveRecord::Migration[8.0]
  def change
    add_reference :daily_reports, :revised_by, foreign_key: { to_table: :employees }, null: true
    add_column :daily_reports, :revised_at, :datetime
  end
end
