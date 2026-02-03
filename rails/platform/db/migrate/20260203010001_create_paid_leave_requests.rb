# frozen_string_literal: true

class CreatePaidLeaveRequests < ActiveRecord::Migration[8.0]
  def change
    create_table :paid_leave_requests do |t|
      t.references :employee, null: false, foreign_key: true
      t.date :leave_date, null: false, comment: "取得日"
      t.string :leave_type, null: false, comment: "full/half_am/half_pm"
      t.text :reason, comment: "申請理由"

      # 承認
      t.string :status, default: "pending", comment: "pending/approved/rejected/cancelled"
      t.references :approved_by, foreign_key: { to_table: :employees }
      t.datetime :approved_at
      t.text :rejection_reason, comment: "却下理由"

      # 消化元
      t.references :paid_leave_grant, foreign_key: true
      t.decimal :consumed_days, precision: 4, scale: 1, null: false, comment: "消化日数"

      t.timestamps
    end

    add_index :paid_leave_requests, [:employee_id, :leave_date], unique: true
    add_index :paid_leave_requests, :status
    add_index :paid_leave_requests, :leave_date
  end
end
