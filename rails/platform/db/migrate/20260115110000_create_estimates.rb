# frozen_string_literal: true

class CreateEstimates < ActiveRecord::Migration[8.0]
  def change
    create_table :estimates do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :project, null: false, foreign_key: true
      t.references :created_by, foreign_key: { to_table: :employees }

      t.string :status, null: false, default: "draft"
      t.string :estimate_number
      t.date :estimate_date
      t.date :valid_until

      # 原価項目
      t.decimal :material_cost, precision: 15, scale: 2, default: 0
      t.decimal :outsourcing_cost, precision: 15, scale: 2, default: 0
      t.decimal :labor_cost, precision: 15, scale: 2, default: 0
      t.decimal :expense_cost, precision: 15, scale: 2, default: 0
      t.decimal :total_cost, precision: 15, scale: 2, default: 0

      # 売価・利益
      t.decimal :selling_price, precision: 15, scale: 2, default: 0
      t.decimal :profit_margin, precision: 5, scale: 2

      t.text :notes

      t.timestamps
    end

    add_index :estimates, %i[tenant_id project_id], unique: true
    add_index :estimates, %i[tenant_id estimate_number], unique: true
  end
end
