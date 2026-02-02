# frozen_string_literal: true

class CreateCashFlowEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :cash_flow_entries do |t|
      t.string :entry_type, null: false              # "income" / "expense"
      t.string :category, null: false                # 科目
      t.string :subcategory                          # サブカテゴリ

      # Polymorphic source (Invoice, Expense, FixedExpenseSchedule等)
      t.references :source, polymorphic: true

      # Related entities
      t.references :client, foreign_key: true
      t.references :partner, foreign_key: true
      t.references :project, foreign_key: true

      # Dates
      t.date :base_date, null: false                 # 基準日（請求日等）
      t.date :expected_date, null: false             # 予定日（自動計算）
      t.date :actual_date                            # 実績日

      # Amounts
      t.decimal :expected_amount, precision: 15, scale: 2, null: false
      t.decimal :actual_amount, precision: 15, scale: 2
      t.decimal :adjustment_amount, precision: 15, scale: 2, default: 0  # 相殺額

      # Status & confirmation
      t.string :status, default: "expected"          # expected, confirmed, completed, cancelled
      t.boolean :manual_override, default: false
      t.text :override_reason

      # Audit
      t.references :confirmed_by, foreign_key: { to_table: :employees }
      t.datetime :confirmed_at
      t.text :notes

      t.timestamps
    end

    add_index :cash_flow_entries, :entry_type
    add_index :cash_flow_entries, :category
    add_index :cash_flow_entries, :expected_date
    add_index :cash_flow_entries, :actual_date
    add_index :cash_flow_entries, :status
    add_index :cash_flow_entries, %i[expected_date entry_type]
  end
end
