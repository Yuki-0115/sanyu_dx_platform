# frozen_string_literal: true

class AddProvisionalFieldsToExpenses < ActiveRecord::Migration[8.0]
  def change
    # 数量・単位（燃料リッター数、高速回数など）
    add_column :expenses, :quantity, :decimal, precision: 10, scale: 2
    add_column :expenses, :unit, :string
    add_column :expenses, :unit_price, :decimal, precision: 12, scale: 2

    # 仮経費フラグと確定情報
    add_column :expenses, :is_provisional, :boolean, default: false
    add_column :expenses, :confirmed_at, :datetime
    add_column :expenses, :confirmed_by_id, :integer

    # 仮金額（請求書到着後に確定金額に更新）
    add_column :expenses, :provisional_amount, :decimal, precision: 15, scale: 2

    add_index :expenses, :is_provisional
    add_index :expenses, :confirmed_by_id
  end
end
