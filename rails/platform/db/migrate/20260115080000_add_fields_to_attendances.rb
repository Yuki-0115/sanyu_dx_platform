# frozen_string_literal: true

class AddFieldsToAttendances < ActiveRecord::Migration[8.0]
  def change
    # 労働時間
    add_column :attendances, :hours_worked, :decimal, precision: 4, scale: 1

    # 協力会社作業員の氏名（employee_idがない場合に使用）
    add_column :attendances, :partner_worker_name, :string

    # employee_idをnullableに変更（協力会社作業員対応）
    change_column_null :attendances, :employee_id, true
  end
end
