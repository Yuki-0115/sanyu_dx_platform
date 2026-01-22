# frozen_string_literal: true

class CreateEstimates < ActiveRecord::Migration[8.0]
  def change
    create_table :estimates do |t|
      t.references :project, null: false, foreign_key: true
      t.references :created_by, foreign_key: { to_table: :employees }

      t.string :status, null: false, default: "draft"
      t.string :estimate_number
      t.date :estimate_date
      t.date :valid_until
      t.integer :version, default: 1

      t.text :notes

      t.timestamps
    end

    add_index :estimates, :estimate_number, unique: true
  end
end
