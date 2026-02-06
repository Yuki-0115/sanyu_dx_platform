# frozen_string_literal: true

class CreateReceivedInvoices < ActiveRecord::Migration[8.0]
  def change
    create_table :received_invoices do |t|
      t.references :partner, foreign_key: true  # 発行元（協力会社）
      t.references :project, foreign_key: true  # 関連案件（任意）
      t.references :uploaded_by, foreign_key: { to_table: :employees }  # アップロード者
      t.references :approved_by, foreign_key: { to_table: :employees }  # 承認者

      t.string :invoice_number       # 請求書番号
      t.string :vendor_name          # 発行元名（協力会社以外の場合）
      t.date :invoice_date           # 請求日
      t.date :due_date               # 支払期限
      t.decimal :amount, precision: 12, scale: 0  # 請求金額（税込）
      t.decimal :tax_amount, precision: 12, scale: 0  # 消費税額
      t.string :description          # 摘要・備考

      t.string :status, null: false, default: "pending"  # pending, approved, rejected, paid
      t.text :rejection_reason       # 却下理由
      t.datetime :approved_at        # 承認日時
      t.datetime :paid_at            # 支払日時

      t.timestamps
    end

    add_index :received_invoices, :status
    add_index :received_invoices, :invoice_date
    add_index :received_invoices, :due_date
  end
end
