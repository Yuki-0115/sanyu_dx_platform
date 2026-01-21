# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_01_21_023306) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "attendances", force: :cascade do |t|
    t.bigint "tenant_id", null: false
    t.bigint "daily_report_id", null: false
    t.bigint "employee_id"
    t.string "attendance_type", null: false
    t.time "start_time"
    t.time "end_time"
    t.integer "travel_distance"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "hours_worked", precision: 4, scale: 1
    t.string "partner_worker_name"
    t.integer "break_minutes", default: 60
    t.integer "overtime_minutes", default: 0
    t.integer "night_minutes", default: 0
    t.integer "travel_minutes", default: 0
    t.string "work_category", default: "work"
    t.string "site_note"
    t.index ["daily_report_id"], name: "index_attendances_on_daily_report_id"
    t.index ["employee_id"], name: "index_attendances_on_employee_id"
    t.index ["tenant_id", "daily_report_id", "employee_id"], name: "idx_attendances_unique", unique: true
    t.index ["tenant_id"], name: "index_attendances_on_tenant_id"
  end

  create_table "audit_logs", force: :cascade do |t|
    t.bigint "tenant_id", null: false
    t.bigint "user_id"
    t.string "auditable_type", null: false
    t.integer "auditable_id", null: false
    t.string "action", null: false
    t.jsonb "changed_data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["auditable_type", "auditable_id"], name: "index_audit_logs_on_auditable_type_and_auditable_id"
    t.index ["created_at"], name: "index_audit_logs_on_created_at"
    t.index ["tenant_id"], name: "index_audit_logs_on_tenant_id"
    t.index ["user_id"], name: "index_audit_logs_on_user_id"
  end

  create_table "budgets", force: :cascade do |t|
    t.bigint "tenant_id", null: false
    t.bigint "project_id", null: false
    t.decimal "target_profit_rate", precision: 5, scale: 2
    t.decimal "material_cost", precision: 15, scale: 2, default: "0.0"
    t.decimal "outsourcing_cost", precision: 15, scale: 2, default: "0.0"
    t.decimal "labor_cost", precision: 15, scale: 2, default: "0.0"
    t.decimal "expense_cost", precision: 15, scale: 2, default: "0.0"
    t.decimal "total_cost", precision: 15, scale: 2, default: "0.0"
    t.text "notes"
    t.string "status", default: "draft"
    t.integer "confirmed_by_id"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["confirmed_by_id"], name: "index_budgets_on_confirmed_by_id"
    t.index ["project_id"], name: "index_budgets_on_project_id"
    t.index ["tenant_id", "project_id"], name: "index_budgets_on_tenant_id_and_project_id", unique: true
    t.index ["tenant_id"], name: "index_budgets_on_tenant_id"
  end

  create_table "clients", force: :cascade do |t|
    t.bigint "tenant_id", null: false
    t.string "code", null: false
    t.string "name", null: false
    t.string "name_kana"
    t.string "postal_code"
    t.text "address"
    t.string "phone"
    t.string "contact_name"
    t.string "contact_email"
    t.string "payment_terms"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tenant_id", "code"], name: "index_clients_on_tenant_id_and_code", unique: true
    t.index ["tenant_id"], name: "index_clients_on_tenant_id"
  end

  create_table "company_events", force: :cascade do |t|
    t.date "event_date", null: false
    t.string "name", null: false
    t.text "description"
    t.string "calendar_type", default: "all", null: false
    t.string "color", default: "purple"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["calendar_type"], name: "index_company_events_on_calendar_type"
    t.index ["event_date", "calendar_type"], name: "index_company_events_on_event_date_and_calendar_type"
    t.index ["event_date"], name: "index_company_events_on_event_date"
  end

  create_table "company_holidays", force: :cascade do |t|
    t.date "holiday_date", null: false
    t.string "calendar_type", null: false
    t.string "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["calendar_type"], name: "index_company_holidays_on_calendar_type"
    t.index ["holiday_date", "calendar_type"], name: "index_company_holidays_on_holiday_date_and_calendar_type", unique: true
    t.index ["holiday_date"], name: "index_company_holidays_on_holiday_date"
  end

  create_table "daily_reports", force: :cascade do |t|
    t.bigint "tenant_id", null: false
    t.bigint "project_id"
    t.bigint "foreman_id", null: false
    t.date "report_date", null: false
    t.string "weather"
    t.text "work_content"
    t.text "notes"
    t.string "status", default: "draft"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "materials_used"
    t.text "machines_used"
    t.text "labor_details"
    t.text "outsourcing_details"
    t.decimal "transportation_cost", precision: 15, scale: 2
    t.bigint "revised_by_id"
    t.datetime "revised_at"
    t.decimal "labor_cost", precision: 15, scale: 2, default: "0.0"
    t.decimal "material_cost", precision: 15, scale: 2, default: "0.0"
    t.decimal "outsourcing_cost", precision: 15, scale: 2, default: "0.0"
    t.boolean "is_external", default: false, null: false
    t.string "external_site_name"
    t.decimal "fuel_quantity", precision: 10, scale: 2
    t.decimal "fuel_amount", precision: 12, scale: 2
    t.boolean "fuel_confirmed", default: false
    t.decimal "fuel_confirmed_amount", precision: 12, scale: 2
    t.integer "highway_count"
    t.decimal "highway_amount", precision: 12, scale: 2
    t.string "highway_route"
    t.boolean "highway_confirmed", default: false
    t.decimal "highway_confirmed_amount", precision: 12, scale: 2
    t.string "fuel_type", default: "regular"
    t.decimal "fuel_unit_price", precision: 10, scale: 2
    t.index ["foreman_id"], name: "index_daily_reports_on_foreman_id"
    t.index ["project_id"], name: "index_daily_reports_on_project_id"
    t.index ["revised_by_id"], name: "index_daily_reports_on_revised_by_id"
    t.index ["tenant_id", "project_id", "report_date"], name: "idx_on_tenant_id_project_id_report_date_7d91023d27", unique: true
    t.index ["tenant_id"], name: "index_daily_reports_on_tenant_id"
  end

  create_table "daily_schedule_notes", force: :cascade do |t|
    t.bigint "tenant_id", null: false
    t.bigint "project_id", null: false
    t.date "scheduled_date", null: false
    t.text "work_content"
    t.text "vehicles"
    t.text "equipment"
    t.text "heavy_equipment_transport"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_daily_schedule_notes_on_project_id"
    t.index ["tenant_id", "project_id", "scheduled_date"], name: "idx_schedule_notes_unique", unique: true
    t.index ["tenant_id"], name: "index_daily_schedule_notes_on_tenant_id"
  end

  create_table "employees", force: :cascade do |t|
    t.bigint "tenant_id", null: false
    t.bigint "partner_id"
    t.string "code", null: false
    t.string "name", null: false
    t.string "name_kana"
    t.string "email"
    t.string "phone"
    t.string "employment_type", null: false
    t.date "hire_date"
    t.string "role", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.decimal "monthly_salary", precision: 12, default: "0"
    t.decimal "social_insurance_monthly", precision: 12, default: "0"
    t.decimal "daily_rate", precision: 10, default: "0"
    t.index ["employment_type"], name: "index_employees_on_employment_type"
    t.index ["partner_id"], name: "index_employees_on_partner_id"
    t.index ["reset_password_token"], name: "index_employees_on_reset_password_token", unique: true
    t.index ["role"], name: "index_employees_on_role"
    t.index ["tenant_id", "code"], name: "index_employees_on_tenant_id_and_code", unique: true
    t.index ["tenant_id", "email"], name: "index_employees_on_tenant_id_and_email", unique: true
    t.index ["tenant_id"], name: "index_employees_on_tenant_id"
  end

  create_table "estimates", force: :cascade do |t|
    t.bigint "tenant_id", null: false
    t.bigint "project_id", null: false
    t.bigint "created_by_id"
    t.string "status", default: "draft", null: false
    t.string "estimate_number"
    t.date "estimate_date"
    t.date "valid_until"
    t.decimal "material_cost", precision: 15, scale: 2, default: "0.0"
    t.decimal "outsourcing_cost", precision: 15, scale: 2, default: "0.0"
    t.decimal "labor_cost", precision: 15, scale: 2, default: "0.0"
    t.decimal "expense_cost", precision: 15, scale: 2, default: "0.0"
    t.decimal "total_cost", precision: 15, scale: 2, default: "0.0"
    t.decimal "selling_price", precision: 15, scale: 2, default: "0.0"
    t.decimal "profit_margin", precision: 5, scale: 2
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_estimates_on_created_by_id"
    t.index ["project_id"], name: "index_estimates_on_project_id"
    t.index ["tenant_id", "estimate_number"], name: "index_estimates_on_tenant_id_and_estimate_number", unique: true
    t.index ["tenant_id", "project_id"], name: "index_estimates_on_tenant_id_and_project_id", unique: true
    t.index ["tenant_id"], name: "index_estimates_on_tenant_id"
  end

  create_table "expenses", force: :cascade do |t|
    t.bigint "tenant_id", null: false
    t.bigint "daily_report_id"
    t.bigint "project_id"
    t.string "expense_type", null: false
    t.string "category", null: false
    t.text "description"
    t.decimal "amount", precision: 15, scale: 2, null: false
    t.bigint "payer_id"
    t.string "payment_method"
    t.string "status", default: "pending"
    t.integer "approved_by_id"
    t.datetime "approved_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "voucher_number"
    t.decimal "quantity", precision: 10, scale: 2
    t.string "unit"
    t.decimal "unit_price", precision: 12, scale: 2
    t.boolean "is_provisional", default: false
    t.datetime "confirmed_at"
    t.integer "confirmed_by_id"
    t.decimal "provisional_amount", precision: 15, scale: 2
    t.index ["approved_by_id"], name: "index_expenses_on_approved_by_id"
    t.index ["confirmed_by_id"], name: "index_expenses_on_confirmed_by_id"
    t.index ["daily_report_id"], name: "index_expenses_on_daily_report_id"
    t.index ["is_provisional"], name: "index_expenses_on_is_provisional"
    t.index ["payer_id"], name: "index_expenses_on_payer_id"
    t.index ["project_id"], name: "index_expenses_on_project_id"
    t.index ["tenant_id"], name: "index_expenses_on_tenant_id"
  end

  create_table "invoice_items", force: :cascade do |t|
    t.bigint "tenant_id", null: false
    t.bigint "invoice_id", null: false
    t.string "name", null: false
    t.date "work_date"
    t.decimal "quantity", precision: 10, scale: 2, default: "1.0"
    t.string "unit", default: "式"
    t.decimal "unit_price", precision: 12, default: "0"
    t.decimal "subtotal", precision: 12, default: "0"
    t.text "description"
    t.integer "position", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["invoice_id", "position"], name: "index_invoice_items_on_invoice_id_and_position"
    t.index ["invoice_id"], name: "index_invoice_items_on_invoice_id"
    t.index ["tenant_id"], name: "index_invoice_items_on_tenant_id"
  end

  create_table "invoices", force: :cascade do |t|
    t.bigint "tenant_id", null: false
    t.bigint "project_id", null: false
    t.string "invoice_number"
    t.decimal "amount", precision: 15, scale: 2, null: false
    t.decimal "tax_amount", precision: 15, scale: 2, default: "0.0"
    t.decimal "total_amount", precision: 15, scale: 2, default: "0.0"
    t.date "issued_date"
    t.date "due_date"
    t.string "status", default: "draft"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_invoices_on_project_id"
    t.index ["status"], name: "index_invoices_on_status"
    t.index ["tenant_id", "invoice_number"], name: "index_invoices_on_tenant_id_and_invoice_number", unique: true
    t.index ["tenant_id"], name: "index_invoices_on_tenant_id"
  end

  create_table "offsets", force: :cascade do |t|
    t.bigint "tenant_id", null: false
    t.bigint "partner_id", null: false
    t.string "year_month", null: false
    t.decimal "total_salary", precision: 15, scale: 2, default: "0.0"
    t.decimal "social_insurance", precision: 15, scale: 2, default: "0.0"
    t.decimal "offset_amount", precision: 15, scale: 2, default: "0.0"
    t.decimal "revenue_amount", precision: 15, scale: 2, default: "0.0"
    t.decimal "balance", precision: 15, scale: 2, default: "0.0"
    t.string "status", default: "draft"
    t.integer "confirmed_by_id"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["confirmed_by_id"], name: "index_offsets_on_confirmed_by_id"
    t.index ["partner_id"], name: "index_offsets_on_partner_id"
    t.index ["tenant_id", "partner_id", "year_month"], name: "index_offsets_on_tenant_id_and_partner_id_and_year_month", unique: true
    t.index ["tenant_id"], name: "index_offsets_on_tenant_id"
  end

  create_table "outsourcing_entries", force: :cascade do |t|
    t.bigint "tenant_id", null: false
    t.bigint "daily_report_id", null: false
    t.bigint "partner_id"
    t.string "partner_name"
    t.integer "headcount", default: 1, null: false
    t.string "attendance_type", default: "full", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["daily_report_id"], name: "index_outsourcing_entries_on_daily_report_id"
    t.index ["partner_id"], name: "index_outsourcing_entries_on_partner_id"
    t.index ["tenant_id", "daily_report_id", "partner_id"], name: "idx_outsourcing_entries_unique_partner", unique: true, where: "(partner_id IS NOT NULL)"
    t.index ["tenant_id"], name: "index_outsourcing_entries_on_tenant_id"
  end

  create_table "partners", force: :cascade do |t|
    t.bigint "tenant_id", null: false
    t.string "code", null: false
    t.string "name", null: false
    t.boolean "has_temporary_employees", default: false
    t.string "offset_rule"
    t.integer "closing_day"
    t.decimal "carryover_balance", precision: 15, scale: 2, default: "0.0"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tenant_id", "code"], name: "index_partners_on_tenant_id_and_code", unique: true
    t.index ["tenant_id"], name: "index_partners_on_tenant_id"
  end

  create_table "payments", force: :cascade do |t|
    t.bigint "tenant_id", null: false
    t.bigint "invoice_id", null: false
    t.date "payment_date", null: false
    t.decimal "amount", precision: 15, scale: 2, null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["invoice_id"], name: "index_payments_on_invoice_id"
    t.index ["tenant_id"], name: "index_payments_on_tenant_id"
  end

  create_table "project_assignments", force: :cascade do |t|
    t.bigint "tenant_id", null: false
    t.bigint "project_id", null: false
    t.bigint "employee_id", null: false
    t.date "start_date"
    t.date "end_date"
    t.string "role"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "shift", default: "day", null: false
    t.index ["employee_id"], name: "index_project_assignments_on_employee_id"
    t.index ["project_id"], name: "index_project_assignments_on_project_id"
    t.index ["tenant_id", "employee_id", "project_id", "shift"], name: "idx_project_assignments_unique", unique: true
    t.index ["tenant_id"], name: "index_project_assignments_on_tenant_id"
  end

  create_table "project_documents", force: :cascade do |t|
    t.bigint "tenant_id", null: false
    t.bigint "project_id", null: false
    t.bigint "uploaded_by_id"
    t.string "name", null: false
    t.string "category", default: "other", null: false
    t.text "description"
    t.date "document_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id", "category"], name: "index_project_documents_on_project_id_and_category"
    t.index ["project_id"], name: "index_project_documents_on_project_id"
    t.index ["tenant_id"], name: "index_project_documents_on_tenant_id"
    t.index ["uploaded_by_id"], name: "index_project_documents_on_uploaded_by_id"
  end

  create_table "projects", force: :cascade do |t|
    t.bigint "tenant_id", null: false
    t.bigint "client_id", null: false
    t.string "code", null: false
    t.string "name", null: false
    t.text "site_address"
    t.decimal "site_lat", precision: 10, scale: 7
    t.decimal "site_lng", precision: 10, scale: 7
    t.boolean "has_contract", default: false
    t.boolean "has_order", default: false
    t.boolean "has_payment_terms", default: false
    t.boolean "has_customer_approval", default: false
    t.datetime "four_point_completed_at"
    t.jsonb "pre_construction_check"
    t.datetime "pre_construction_approved_at"
    t.decimal "estimated_amount", precision: 15, scale: 2
    t.decimal "order_amount", precision: 15, scale: 2
    t.decimal "budget_amount", precision: 15, scale: 2
    t.decimal "actual_cost", precision: 15, scale: 2
    t.string "status", default: "draft"
    t.integer "sales_user_id"
    t.integer "engineering_user_id"
    t.integer "construction_user_id"
    t.text "drive_folder_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "project_type", default: "regular", null: false
    t.boolean "site_conditions_checked", default: false
    t.boolean "night_work_checked", default: false
    t.boolean "regulations_checked", default: false
    t.boolean "safety_docs_checked", default: false
    t.boolean "delivery_checked", default: false
    t.datetime "pre_construction_gate_completed_at"
    t.date "scheduled_start_date"
    t.date "scheduled_end_date"
    t.date "actual_start_date"
    t.date "actual_end_date"
    t.string "order_flow", default: "standard"
    t.datetime "oral_order_received_at"
    t.datetime "order_document_received_at"
    t.decimal "oral_order_amount", precision: 15, scale: 2
    t.text "oral_order_note"
    t.index ["client_id"], name: "index_projects_on_client_id"
    t.index ["construction_user_id"], name: "index_projects_on_construction_user_id"
    t.index ["engineering_user_id"], name: "index_projects_on_engineering_user_id"
    t.index ["project_type"], name: "index_projects_on_project_type"
    t.index ["sales_user_id"], name: "index_projects_on_sales_user_id"
    t.index ["scheduled_end_date"], name: "index_projects_on_scheduled_end_date"
    t.index ["scheduled_start_date"], name: "index_projects_on_scheduled_start_date"
    t.index ["status"], name: "index_projects_on_status"
    t.index ["tenant_id", "code"], name: "index_projects_on_tenant_id_and_code", unique: true
    t.index ["tenant_id"], name: "index_projects_on_tenant_id"
  end

  create_table "safety_files", force: :cascade do |t|
    t.bigint "tenant_id", null: false
    t.bigint "safety_folder_id", null: false
    t.string "name", null: false
    t.text "description"
    t.bigint "uploaded_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["safety_folder_id"], name: "index_safety_files_on_safety_folder_id"
    t.index ["tenant_id"], name: "index_safety_files_on_tenant_id"
  end

  create_table "safety_folders", force: :cascade do |t|
    t.bigint "tenant_id", null: false
    t.bigint "project_id"
    t.string "name", null: false
    t.text "description"
    t.integer "files_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_safety_folders_on_project_id"
    t.index ["tenant_id", "name"], name: "index_safety_folders_on_tenant_id_and_name"
    t.index ["tenant_id", "project_id"], name: "index_safety_folders_on_tenant_id_and_project_id"
    t.index ["tenant_id"], name: "index_safety_folders_on_tenant_id"
  end

  create_table "tenants", force: :cascade do |t|
    t.string "code", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_tenants_on_code", unique: true
  end

  create_table "work_schedules", force: :cascade do |t|
    t.bigint "tenant_id", null: false
    t.date "scheduled_date", null: false
    t.string "shift", default: "day", null: false
    t.bigint "employee_id", null: false
    t.string "site_name"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "project_id"
    t.string "role", default: "worker"
    t.index ["employee_id"], name: "index_work_schedules_on_employee_id"
    t.index ["project_id"], name: "index_work_schedules_on_project_id"
    t.index ["scheduled_date", "shift"], name: "index_work_schedules_on_scheduled_date_and_shift"
    t.index ["tenant_id", "scheduled_date", "shift", "project_id", "employee_id"], name: "idx_work_schedules_unique", unique: true
    t.index ["tenant_id"], name: "index_work_schedules_on_tenant_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "attendances", "daily_reports"
  add_foreign_key "attendances", "employees"
  add_foreign_key "attendances", "tenants"
  add_foreign_key "audit_logs", "employees", column: "user_id"
  add_foreign_key "audit_logs", "tenants"
  add_foreign_key "budgets", "projects"
  add_foreign_key "budgets", "tenants"
  add_foreign_key "clients", "tenants"
  add_foreign_key "daily_reports", "employees", column: "foreman_id"
  add_foreign_key "daily_reports", "employees", column: "revised_by_id"
  add_foreign_key "daily_reports", "projects"
  add_foreign_key "daily_reports", "tenants"
  add_foreign_key "daily_schedule_notes", "projects"
  add_foreign_key "daily_schedule_notes", "tenants"
  add_foreign_key "employees", "partners"
  add_foreign_key "employees", "tenants"
  add_foreign_key "estimates", "employees", column: "created_by_id"
  add_foreign_key "estimates", "projects"
  add_foreign_key "estimates", "tenants"
  add_foreign_key "expenses", "daily_reports"
  add_foreign_key "expenses", "employees", column: "payer_id"
  add_foreign_key "expenses", "projects"
  add_foreign_key "expenses", "tenants"
  add_foreign_key "invoice_items", "invoices"
  add_foreign_key "invoice_items", "tenants"
  add_foreign_key "invoices", "projects"
  add_foreign_key "invoices", "tenants"
  add_foreign_key "offsets", "partners"
  add_foreign_key "offsets", "tenants"
  add_foreign_key "outsourcing_entries", "daily_reports"
  add_foreign_key "outsourcing_entries", "partners"
  add_foreign_key "outsourcing_entries", "tenants"
  add_foreign_key "partners", "tenants"
  add_foreign_key "payments", "invoices"
  add_foreign_key "payments", "tenants"
  add_foreign_key "project_assignments", "employees"
  add_foreign_key "project_assignments", "projects"
  add_foreign_key "project_assignments", "tenants"
  add_foreign_key "project_documents", "employees", column: "uploaded_by_id"
  add_foreign_key "project_documents", "projects"
  add_foreign_key "project_documents", "tenants"
  add_foreign_key "projects", "clients"
  add_foreign_key "projects", "tenants"
  add_foreign_key "safety_files", "employees", column: "uploaded_by_id"
  add_foreign_key "safety_files", "safety_folders"
  add_foreign_key "safety_files", "tenants"
  add_foreign_key "safety_folders", "projects"
  add_foreign_key "safety_folders", "tenants"
  add_foreign_key "work_schedules", "employees"
  add_foreign_key "work_schedules", "projects"
  add_foreign_key "work_schedules", "tenants"
end
