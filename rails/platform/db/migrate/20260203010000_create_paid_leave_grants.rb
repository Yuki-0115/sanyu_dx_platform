# frozen_string_literal: true

class CreatePaidLeaveGrants < ActiveRecord::Migration[8.0]
  def change
    create_table :paid_leave_grants do |t|
      t.references :employee, null: false, foreign_key: true
      t.date :grant_date, null: false, comment: "付与日（基準日）"
      t.date :expiry_date, null: false, comment: "失効日（付与日+2年）"
      t.decimal :granted_days, precision: 4, scale: 1, null: false, comment: "付与日数"
      t.decimal :used_days, precision: 4, scale: 1, default: 0, comment: "使用済日数"
      t.decimal :expired_days, precision: 4, scale: 1, default: 0, comment: "失効日数"
      t.decimal :remaining_days, precision: 4, scale: 1, null: false, comment: "残日数"
      t.integer :fiscal_year, null: false, comment: "対象年度"
      t.string :grant_type, default: "auto", comment: "auto=自動/manual=手動/special=特別"
      t.text :notes, comment: "備考"

      t.timestamps
    end

    add_index :paid_leave_grants, [:employee_id, :grant_date], unique: true
    add_index :paid_leave_grants, :expiry_date
    add_index :paid_leave_grants, :fiscal_year
  end
end
