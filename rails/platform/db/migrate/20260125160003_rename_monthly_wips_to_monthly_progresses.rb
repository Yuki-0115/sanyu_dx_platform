# frozen_string_literal: true

class RenameMonthlyWipsToMonthlyProgresses < ActiveRecord::Migration[8.0]
  def change
    # テーブル名変更
    rename_table :monthly_wips, :monthly_progresses

    # カラム名変更
    rename_column :monthly_progresses, :revenue, :progress_amount
    rename_column :monthly_progresses, :cost, :progress_cost

    # コメント更新
    change_column_comment :monthly_progresses, :progress_amount, "月次出来高金額"
    change_column_comment :monthly_progresses, :progress_cost, "月次出来高原価"
  end
end
