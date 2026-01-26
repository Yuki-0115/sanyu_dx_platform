# frozen_string_literal: true

class AddAccountingFieldsToExpenses < ActiveRecord::Migration[8.0]
  def change
    # 勘定科目コード（freee/MoneyForward連携用）
    add_column :expenses, :account_code, :string

    # 経理処理ステータス（pending_accounting: 経理未処理, processed: 処理済み）
    add_column :expenses, :accounting_status, :string, default: "pending_accounting"

    # 経理処理者
    add_reference :expenses, :processed_by, foreign_key: { to_table: :employees }

    # 経理処理日時
    add_column :expenses, :processed_at, :datetime

    # 経理メモ（税区分変更理由など）
    add_column :expenses, :accounting_note, :text

    # 税区分（課税/非課税/不課税）
    add_column :expenses, :tax_category, :string, default: "taxable"

    add_index :expenses, :accounting_status
    add_index :expenses, :account_code
  end
end
