# frozen_string_literal: true

class CreateDataImports < ActiveRecord::Migration[8.0]
  def change
    create_table :data_imports do |t|
      t.string :import_type, null: false  # clients, partners, employees, projects, paid_leaves, offsets, invoices
      t.string :status, default: "pending"  # pending, processing, completed, failed
      t.string :file_name
      t.integer :total_rows, default: 0
      t.integer :success_rows, default: 0
      t.integer :error_rows, default: 0
      t.jsonb :error_details, default: []  # [{row: 1, errors: ["..."]}]
      t.jsonb :skipped_rows, default: []   # [{row: 1, reason: "..."}]
      t.references :imported_by, foreign_key: { to_table: :employees }
      t.timestamps
    end

    add_index :data_imports, :import_type
    add_index :data_imports, :status
  end
end
