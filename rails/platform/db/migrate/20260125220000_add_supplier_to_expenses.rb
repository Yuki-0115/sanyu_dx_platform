# frozen_string_literal: true

class AddSupplierToExpenses < ActiveRecord::Migration[8.0]
  def change
    # 仕入先（Partnerマスタを使用）
    add_reference :expenses, :supplier, foreign_key: { to_table: :partners }

    # 精算対象フラグ（現金・立替の場合）
    add_column :expenses, :reimbursement_required, :boolean, default: false

    # 精算済みフラグ
    add_column :expenses, :reimbursed, :boolean, default: false
    add_column :expenses, :reimbursed_at, :datetime

    add_index :expenses, :reimbursement_required
  end
end
