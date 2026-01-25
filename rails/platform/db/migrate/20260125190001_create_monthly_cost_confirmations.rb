# frozen_string_literal: true

class CreateMonthlyCostConfirmations < ActiveRecord::Migration[8.0]
  def change
    create_table :monthly_cost_confirmations do |t|
      t.integer :year, null: false, comment: "年"
      t.integer :month, null: false, comment: "月"
      t.string :cost_type, null: false, comment: "費用種別(material/expense)"
      t.references :confirmed_by, foreign_key: { to_table: :employees }, comment: "確認者"
      t.datetime :confirmed_at, comment: "確認日時"

      t.timestamps
    end

    add_index :monthly_cost_confirmations, [:year, :month, :cost_type], unique: true,
              name: "idx_monthly_cost_confirmations_unique"
  end
end
