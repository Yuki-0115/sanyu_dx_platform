class CreateAuditLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :audit_logs do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :user, foreign_key: { to_table: :employees }
      t.string :auditable_type, null: false
      t.integer :auditable_id, null: false
      t.string :action, null: false
      t.jsonb :changed_data

      t.timestamps
    end

    add_index :audit_logs, %i[auditable_type auditable_id]
    add_index :audit_logs, :created_at
  end
end
