# frozen_string_literal: true

class RemoveTenantFromAllTables < ActiveRecord::Migration[8.0]
  def change
    # Remove foreign keys first
    remove_foreign_key :attendances, :tenants if foreign_key_exists?(:attendances, :tenants)
    remove_foreign_key :audit_logs, :tenants if foreign_key_exists?(:audit_logs, :tenants)
    remove_foreign_key :budgets, :tenants if foreign_key_exists?(:budgets, :tenants)
    remove_foreign_key :clients, :tenants if foreign_key_exists?(:clients, :tenants)
    remove_foreign_key :daily_reports, :tenants if foreign_key_exists?(:daily_reports, :tenants)
    remove_foreign_key :daily_schedule_notes, :tenants if foreign_key_exists?(:daily_schedule_notes, :tenants)
    remove_foreign_key :employees, :tenants if foreign_key_exists?(:employees, :tenants)
    remove_foreign_key :estimates, :tenants if foreign_key_exists?(:estimates, :tenants)
    remove_foreign_key :expenses, :tenants if foreign_key_exists?(:expenses, :tenants)
    remove_foreign_key :invoice_items, :tenants if foreign_key_exists?(:invoice_items, :tenants)
    remove_foreign_key :invoices, :tenants if foreign_key_exists?(:invoices, :tenants)
    remove_foreign_key :offsets, :tenants if foreign_key_exists?(:offsets, :tenants)
    remove_foreign_key :outsourcing_entries, :tenants if foreign_key_exists?(:outsourcing_entries, :tenants)
    remove_foreign_key :partners, :tenants if foreign_key_exists?(:partners, :tenants)
    remove_foreign_key :payments, :tenants if foreign_key_exists?(:payments, :tenants)
    remove_foreign_key :project_assignments, :tenants if foreign_key_exists?(:project_assignments, :tenants)
    remove_foreign_key :project_documents, :tenants if foreign_key_exists?(:project_documents, :tenants)
    remove_foreign_key :projects, :tenants if foreign_key_exists?(:projects, :tenants)
    remove_foreign_key :safety_files, :tenants if foreign_key_exists?(:safety_files, :tenants)
    remove_foreign_key :safety_folders, :tenants if foreign_key_exists?(:safety_folders, :tenants)
    remove_foreign_key :work_schedules, :tenants if foreign_key_exists?(:work_schedules, :tenants)

    # Remove tenant_id columns
    remove_column :attendances, :tenant_id, :bigint if column_exists?(:attendances, :tenant_id)
    remove_column :audit_logs, :tenant_id, :bigint if column_exists?(:audit_logs, :tenant_id)
    remove_column :budgets, :tenant_id, :bigint if column_exists?(:budgets, :tenant_id)
    remove_column :clients, :tenant_id, :bigint if column_exists?(:clients, :tenant_id)
    remove_column :daily_reports, :tenant_id, :bigint if column_exists?(:daily_reports, :tenant_id)
    remove_column :daily_schedule_notes, :tenant_id, :bigint if column_exists?(:daily_schedule_notes, :tenant_id)
    remove_column :employees, :tenant_id, :bigint if column_exists?(:employees, :tenant_id)
    remove_column :estimates, :tenant_id, :bigint if column_exists?(:estimates, :tenant_id)
    remove_column :expenses, :tenant_id, :bigint if column_exists?(:expenses, :tenant_id)
    remove_column :invoice_items, :tenant_id, :bigint if column_exists?(:invoice_items, :tenant_id)
    remove_column :invoices, :tenant_id, :bigint if column_exists?(:invoices, :tenant_id)
    remove_column :offsets, :tenant_id, :bigint if column_exists?(:offsets, :tenant_id)
    remove_column :outsourcing_entries, :tenant_id, :bigint if column_exists?(:outsourcing_entries, :tenant_id)
    remove_column :partners, :tenant_id, :bigint if column_exists?(:partners, :tenant_id)
    remove_column :payments, :tenant_id, :bigint if column_exists?(:payments, :tenant_id)
    remove_column :project_assignments, :tenant_id, :bigint if column_exists?(:project_assignments, :tenant_id)
    remove_column :project_documents, :tenant_id, :bigint if column_exists?(:project_documents, :tenant_id)
    remove_column :projects, :tenant_id, :bigint if column_exists?(:projects, :tenant_id)
    remove_column :safety_files, :tenant_id, :bigint if column_exists?(:safety_files, :tenant_id)
    remove_column :safety_folders, :tenant_id, :bigint if column_exists?(:safety_folders, :tenant_id)
    remove_column :work_schedules, :tenant_id, :bigint if column_exists?(:work_schedules, :tenant_id)

    # Drop tenants table
    drop_table :tenants if table_exists?(:tenants)
  end
end
