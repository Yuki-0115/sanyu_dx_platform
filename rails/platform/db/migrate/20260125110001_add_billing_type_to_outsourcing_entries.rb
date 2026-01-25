# frozen_string_literal: true

class AddBillingTypeToOutsourcingEntries < ActiveRecord::Migration[8.0]
  def change
    # 外注の請求種別: man_days(人工) or contract(請負)
    add_column :outsourcing_entries, :billing_type, :string, default: "man_days", null: false

    # 請負金額（billing_type が contract の場合に使用）
    add_column :outsourcing_entries, :contract_amount, :decimal, precision: 15, scale: 0, default: 0

    add_index :outsourcing_entries, :billing_type
  end
end
