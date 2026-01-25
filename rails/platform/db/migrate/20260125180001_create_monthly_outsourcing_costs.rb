# frozen_string_literal: true

class CreateMonthlyOutsourcingCosts < ActiveRecord::Migration[8.0]
  def change
    create_table :monthly_outsourcing_costs do |t|
      t.integer :year, null: false, comment: "年"
      t.integer :month, null: false, comment: "月"
      t.references :partner, null: false, foreign_key: true, comment: "協力会社"
      t.references :project, null: false, foreign_key: true, comment: "案件"
      t.decimal :amount, precision: 12, scale: 0, default: 0, comment: "確定金額"
      t.text :note, comment: "備考"

      t.timestamps
    end

    add_index :monthly_outsourcing_costs, [:year, :month, :partner_id, :project_id],
              unique: true, name: "idx_monthly_outsourcing_costs_unique"
    add_index :monthly_outsourcing_costs, [:year, :month]
  end
end
