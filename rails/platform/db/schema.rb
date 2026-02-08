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

ActiveRecord::Schema[8.0].define(version: 2026_02_08_073619) do
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
  end

  create_table "audit_logs", force: :cascade do |t|
    t.bigint "user_id"
    t.string "auditable_type", null: false
    t.integer "auditable_id", null: false
    t.string "action", null: false
    t.jsonb "changed_data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["auditable_type", "auditable_id"], name: "index_audit_logs_on_auditable_type_and_auditable_id"
    t.index ["created_at"], name: "index_audit_logs_on_created_at"
    t.index ["user_id"], name: "index_audit_logs_on_user_id"
  end

  create_table "budgets", force: :cascade do |t|
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
    t.decimal "regular_labor_unit_price", precision: 10, default: "18000"
    t.decimal "temporary_labor_unit_price", precision: 10, default: "18000"
    t.decimal "outsourcing_unit_price", precision: 10, default: "18000"
    t.decimal "machinery_own_cost", precision: 12, default: "0"
    t.decimal "machinery_rental_cost", precision: 12, default: "0"
    t.index ["confirmed_by_id"], name: "index_budgets_on_confirmed_by_id"
    t.index ["project_id"], name: "index_budgets_on_project_id"
  end

  create_table "cash_flow_entries", force: :cascade do |t|
    t.string "entry_type", null: false
    t.string "category", null: false
    t.string "subcategory"
    t.string "source_type"
    t.bigint "source_id"
    t.bigint "client_id"
    t.bigint "partner_id"
    t.bigint "project_id"
    t.date "base_date", null: false
    t.date "expected_date", null: false
    t.date "actual_date"
    t.decimal "expected_amount", precision: 15, scale: 2, null: false
    t.decimal "actual_amount", precision: 15, scale: 2
    t.decimal "adjustment_amount", precision: 15, scale: 2, default: "0.0"
    t.string "status", default: "expected"
    t.boolean "manual_override", default: false
    t.text "override_reason"
    t.bigint "confirmed_by_id"
    t.datetime "confirmed_at"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["actual_date"], name: "index_cash_flow_entries_on_actual_date"
    t.index ["category"], name: "index_cash_flow_entries_on_category"
    t.index ["client_id"], name: "index_cash_flow_entries_on_client_id"
    t.index ["confirmed_by_id"], name: "index_cash_flow_entries_on_confirmed_by_id"
    t.index ["entry_type"], name: "index_cash_flow_entries_on_entry_type"
    t.index ["expected_date", "entry_type"], name: "index_cash_flow_entries_on_expected_date_and_entry_type"
    t.index ["expected_date"], name: "index_cash_flow_entries_on_expected_date"
    t.index ["partner_id"], name: "index_cash_flow_entries_on_partner_id"
    t.index ["project_id"], name: "index_cash_flow_entries_on_project_id"
    t.index ["source_type", "source_id"], name: "index_cash_flow_entries_on_source"
    t.index ["status"], name: "index_cash_flow_entries_on_status"
  end

  create_table "clients", force: :cascade do |t|
    t.string "code", null: false
    t.string "name", null: false
    t.string "name_kana"
    t.string "postal_code"
    t.text "address"
    t.string "phone"
    t.string "contact_name"
    t.string "contact_email"
    t.string "payment_terms_text"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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

  create_table "cost_breakdown_templates", force: :cascade do |t|
    t.string "name", null: false
    t.string "category"
    t.string "unit", default: "式"
    t.decimal "default_unit_price", precision: 15, scale: 2
    t.text "note"
    t.integer "sort_order", default: 0
    t.boolean "is_shared", default: false
    t.bigint "employee_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_cost_breakdown_templates_on_category"
    t.index ["employee_id"], name: "index_cost_breakdown_templates_on_employee_id"
    t.index ["is_shared"], name: "index_cost_breakdown_templates_on_is_shared"
  end

  create_table "cost_units", force: :cascade do |t|
    t.string "name", null: false
    t.integer "sort_order", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_cost_units_on_name", unique: true
    t.index ["sort_order"], name: "index_cost_units_on_sort_order"
  end

  create_table "daily_reports", force: :cascade do |t|
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
    t.decimal "machinery_own_cost", precision: 12, default: "0"
    t.decimal "machinery_rental_cost", precision: 12, default: "0"
    t.index ["foreman_id"], name: "index_daily_reports_on_foreman_id"
    t.index ["project_id"], name: "index_daily_reports_on_project_id"
    t.index ["revised_by_id"], name: "index_daily_reports_on_revised_by_id"
  end

  create_table "daily_schedule_notes", force: :cascade do |t|
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
  end

  create_table "data_imports", force: :cascade do |t|
    t.string "import_type", null: false
    t.string "status", default: "pending"
    t.string "file_name"
    t.integer "total_rows", default: 0
    t.integer "success_rows", default: 0
    t.integer "error_rows", default: 0
    t.jsonb "error_details", default: []
    t.jsonb "skipped_rows", default: []
    t.bigint "imported_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["import_type"], name: "index_data_imports_on_import_type"
    t.index ["imported_by_id"], name: "index_data_imports_on_imported_by_id"
    t.index ["status"], name: "index_data_imports_on_status"
  end

  create_table "employees", force: :cascade do |t|
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
    t.date "birth_date"
    t.date "paid_leave_base_date", comment: "有給基準日"
    t.index ["employment_type"], name: "index_employees_on_employment_type"
    t.index ["partner_id"], name: "index_employees_on_partner_id"
    t.index ["reset_password_token"], name: "index_employees_on_reset_password_token", unique: true
    t.index ["role"], name: "index_employees_on_role"
  end

  create_table "estimate_categories", force: :cascade do |t|
    t.bigint "estimate_id", null: false
    t.string "name", null: false
    t.decimal "overhead_rate", precision: 5, scale: 2, default: "0.0"
    t.decimal "welfare_rate", precision: 5, scale: 2, default: "0.0"
    t.integer "sort_order", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["estimate_id", "sort_order"], name: "index_estimate_categories_on_estimate_id_and_sort_order"
    t.index ["estimate_id"], name: "index_estimate_categories_on_estimate_id"
  end

  create_table "estimate_confirmations", force: :cascade do |t|
    t.bigint "estimate_id", null: false
    t.string "item_category"
    t.string "item_name"
    t.string "responsibility"
    t.text "note"
    t.integer "sort_order", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["estimate_id", "sort_order"], name: "index_estimate_confirmations_on_estimate_id_and_sort_order"
    t.index ["estimate_id"], name: "index_estimate_confirmations_on_estimate_id"
  end

  create_table "estimate_item_costs", force: :cascade do |t|
    t.bigint "estimate_item_id", null: false
    t.string "cost_name"
    t.decimal "quantity", precision: 15, scale: 4
    t.string "unit"
    t.decimal "unit_price", precision: 15, scale: 2
    t.decimal "amount", precision: 15, scale: 2
    t.string "calculation_type"
    t.jsonb "formula_params", default: {}
    t.text "note"
    t.integer "sort_order", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["estimate_item_id", "sort_order"], name: "index_estimate_item_costs_on_estimate_item_id_and_sort_order"
    t.index ["estimate_item_id"], name: "index_estimate_item_costs_on_estimate_item_id"
  end

  create_table "estimate_item_templates", force: :cascade do |t|
    t.string "name", null: false
    t.string "category"
    t.string "unit"
    t.decimal "default_unit_price", precision: 12, scale: 2
    t.string "specification"
    t.string "note"
    t.integer "sort_order", default: 0
    t.boolean "is_shared", default: false
    t.bigint "employee_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_estimate_item_templates_on_category"
    t.index ["employee_id"], name: "index_estimate_item_templates_on_employee_id"
    t.index ["is_shared"], name: "index_estimate_item_templates_on_is_shared"
  end

  create_table "estimate_items", force: :cascade do |t|
    t.bigint "estimate_id", null: false
    t.string "name"
    t.string "specification"
    t.decimal "quantity", precision: 15, scale: 4
    t.string "unit"
    t.decimal "unit_price", precision: 15, scale: 2
    t.decimal "amount", precision: 15, scale: 2
    t.text "note"
    t.decimal "budget_quantity", precision: 15, scale: 4
    t.string "budget_unit"
    t.decimal "budget_unit_price", precision: 15, scale: 2
    t.decimal "budget_amount", precision: 15, scale: 2
    t.integer "construction_days"
    t.integer "sort_order", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "estimate_category_id"
    t.index ["estimate_category_id"], name: "index_estimate_items_on_estimate_category_id"
    t.index ["estimate_id", "sort_order"], name: "index_estimate_items_on_estimate_id_and_sort_order"
    t.index ["estimate_id"], name: "index_estimate_items_on_estimate_id"
  end

  create_table "estimate_templates", force: :cascade do |t|
    t.string "template_type", null: false
    t.string "name", null: false
    t.text "content"
    t.boolean "is_shared", default: false, null: false
    t.bigint "employee_id"
    t.integer "sort_order", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["employee_id"], name: "index_estimate_templates_on_employee_id"
    t.index ["template_type", "employee_id"], name: "index_estimate_templates_on_template_type_and_employee_id"
    t.index ["template_type", "is_shared"], name: "index_estimate_templates_on_template_type_and_is_shared"
  end

  create_table "estimates", force: :cascade do |t|
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
    t.string "recipient"
    t.string "subject"
    t.string "location"
    t.date "period_start"
    t.date "period_end"
    t.string "validity_period", default: "3ヵ月"
    t.text "payment_terms"
    t.text "waste_disposal_note"
    t.text "special_note"
    t.string "person_in_charge"
    t.decimal "overhead_rate", precision: 5, scale: 2, default: "4.0"
    t.decimal "welfare_rate", precision: 5, scale: 2, default: "3.0"
    t.integer "adjustment", default: 0
    t.text "conditions"
    t.index ["created_by_id"], name: "index_estimates_on_created_by_id"
    t.index ["project_id"], name: "index_estimates_on_project_id"
  end

  create_table "expenses", force: :cascade do |t|
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
    t.string "account_code"
    t.string "accounting_status", default: "pending_accounting"
    t.bigint "processed_by_id"
    t.datetime "processed_at"
    t.text "accounting_note"
    t.string "tax_category", default: "taxable"
    t.bigint "supplier_id"
    t.boolean "reimbursement_required", default: false
    t.boolean "reimbursed", default: false
    t.datetime "reimbursed_at"
    t.string "payee_name"
    t.index ["account_code"], name: "index_expenses_on_account_code"
    t.index ["accounting_status"], name: "index_expenses_on_accounting_status"
    t.index ["approved_by_id"], name: "index_expenses_on_approved_by_id"
    t.index ["confirmed_by_id"], name: "index_expenses_on_confirmed_by_id"
    t.index ["daily_report_id"], name: "index_expenses_on_daily_report_id"
    t.index ["is_provisional"], name: "index_expenses_on_is_provisional"
    t.index ["payer_id"], name: "index_expenses_on_payer_id"
    t.index ["processed_by_id"], name: "index_expenses_on_processed_by_id"
    t.index ["project_id"], name: "index_expenses_on_project_id"
    t.index ["reimbursement_required"], name: "index_expenses_on_reimbursement_required"
    t.index ["supplier_id"], name: "index_expenses_on_supplier_id"
  end

  create_table "fixed_expense_monthly_amounts", force: :cascade do |t|
    t.bigint "fixed_expense_schedule_id", null: false
    t.integer "year", null: false
    t.integer "month", null: false
    t.decimal "amount", precision: 15, scale: 2, null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["fixed_expense_schedule_id", "year", "month"], name: "idx_fixed_expense_monthly_amounts_unique", unique: true
    t.index ["fixed_expense_schedule_id"], name: "idx_on_fixed_expense_schedule_id_5a5b8eac48"
  end

  create_table "fixed_expense_schedules", force: :cascade do |t|
    t.string "name", null: false
    t.string "category", null: false
    t.integer "payment_day", null: false
    t.decimal "amount", precision: 15, scale: 2
    t.boolean "amount_variable", default: false
    t.boolean "active", default: true
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "payment_type", default: "fixed", null: false
    t.integer "one_time_year"
    t.integer "one_time_month"
    t.index ["active"], name: "index_fixed_expense_schedules_on_active"
    t.index ["category"], name: "index_fixed_expense_schedules_on_category"
    t.index ["payment_type"], name: "index_fixed_expense_schedules_on_payment_type"
  end

  create_table "invoice_items", force: :cascade do |t|
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
  end

  create_table "invoices", force: :cascade do |t|
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
    t.integer "progress_year", comment: "対象年"
    t.integer "progress_month", comment: "対象月"
    t.bigint "payment_term_id"
    t.date "expected_payment_date"
    t.index ["payment_term_id"], name: "index_invoices_on_payment_term_id"
    t.index ["progress_year", "progress_month"], name: "index_invoices_on_progress_year_and_progress_month"
    t.index ["project_id"], name: "index_invoices_on_project_id"
    t.index ["status"], name: "index_invoices_on_status"
  end

  create_table "monthly_admin_expenses", force: :cascade do |t|
    t.integer "year", null: false, comment: "年"
    t.integer "month", null: false, comment: "月"
    t.string "category", null: false, comment: "カテゴリ"
    t.string "name", null: false, comment: "項目名"
    t.decimal "amount", precision: 12, default: "0", null: false, comment: "金額"
    t.text "description", comment: "備考"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["year", "month", "category"], name: "index_monthly_admin_expenses_on_year_and_month_and_category"
    t.index ["year", "month"], name: "index_monthly_admin_expenses_on_year_and_month"
  end

  create_table "monthly_cost_confirmations", force: :cascade do |t|
    t.integer "year", null: false, comment: "年"
    t.integer "month", null: false, comment: "月"
    t.string "cost_type", null: false, comment: "費用種別(material/expense)"
    t.bigint "confirmed_by_id", comment: "確認者"
    t.datetime "confirmed_at", comment: "確認日時"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["confirmed_by_id"], name: "index_monthly_cost_confirmations_on_confirmed_by_id"
    t.index ["year", "month", "cost_type"], name: "idx_monthly_cost_confirmations_unique", unique: true
  end

  create_table "monthly_fixed_costs", force: :cascade do |t|
    t.integer "year", null: false
    t.integer "month", null: false
    t.string "name", null: false
    t.string "category", default: "other", null: false
    t.decimal "amount", precision: 15, default: "0", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["year", "month", "category"], name: "index_monthly_fixed_costs_on_year_and_month_and_category"
    t.index ["year", "month"], name: "index_monthly_fixed_costs_on_year_and_month"
  end

  create_table "monthly_outsourcing_costs", force: :cascade do |t|
    t.integer "year", null: false, comment: "年"
    t.integer "month", null: false, comment: "月"
    t.bigint "partner_id", null: false, comment: "協力会社"
    t.bigint "project_id", null: false, comment: "案件"
    t.decimal "amount", precision: 12, default: "0", comment: "確定金額"
    t.text "note", comment: "備考"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["partner_id"], name: "index_monthly_outsourcing_costs_on_partner_id"
    t.index ["project_id"], name: "index_monthly_outsourcing_costs_on_project_id"
    t.index ["year", "month", "partner_id", "project_id"], name: "idx_monthly_outsourcing_costs_unique", unique: true
    t.index ["year", "month"], name: "index_monthly_outsourcing_costs_on_year_and_month"
  end

  create_table "monthly_progresses", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.integer "year", null: false
    t.integer "month", null: false
    t.decimal "progress_amount", precision: 15, default: "0", comment: "月次出来高金額"
    t.decimal "progress_cost", precision: 15, default: "0", comment: "月次出来高原価"
    t.text "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id", "year", "month"], name: "index_monthly_progresses_on_project_id_and_year_and_month", unique: true
    t.index ["project_id"], name: "index_monthly_progresses_on_project_id"
    t.index ["year", "month"], name: "index_monthly_progresses_on_year_and_month"
  end

  create_table "monthly_salaries", force: :cascade do |t|
    t.bigint "employee_id", null: false
    t.integer "year", null: false
    t.integer "month", null: false
    t.decimal "total_amount", precision: 15, default: "0", null: false
    t.text "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["employee_id", "year", "month"], name: "index_monthly_salaries_on_employee_id_and_year_and_month", unique: true
    t.index ["employee_id"], name: "index_monthly_salaries_on_employee_id"
    t.index ["year", "month"], name: "index_monthly_salaries_on_year_and_month"
  end

  create_table "offsets", force: :cascade do |t|
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
  end

  create_table "outsourcing_entries", force: :cascade do |t|
    t.bigint "daily_report_id", null: false
    t.bigint "partner_id"
    t.string "partner_name"
    t.integer "headcount", default: 1, null: false
    t.string "attendance_type", default: "full", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "billing_type", default: "man_days", null: false
    t.decimal "contract_amount", precision: 15, default: "0"
    t.decimal "quantity", precision: 10, scale: 2
    t.string "unit"
    t.text "work_description"
    t.index ["billing_type"], name: "index_outsourcing_entries_on_billing_type"
    t.index ["daily_report_id"], name: "index_outsourcing_entries_on_daily_report_id"
    t.index ["partner_id"], name: "index_outsourcing_entries_on_partner_id"
  end

  create_table "outsourcing_schedules", force: :cascade do |t|
    t.date "scheduled_date", null: false
    t.string "shift", default: "day", null: false
    t.bigint "project_id", null: false
    t.bigint "partner_id", null: false
    t.integer "headcount", default: 1
    t.string "billing_type", default: "man_days", null: false
    t.string "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["partner_id"], name: "index_outsourcing_schedules_on_partner_id"
    t.index ["project_id"], name: "index_outsourcing_schedules_on_project_id"
    t.index ["scheduled_date", "project_id", "partner_id", "shift"], name: "idx_outsourcing_schedules_unique", unique: true
  end

  create_table "paid_leave_grants", force: :cascade do |t|
    t.bigint "employee_id", null: false
    t.date "grant_date", null: false, comment: "付与日（基準日）"
    t.date "expiry_date", null: false, comment: "失効日（付与日+2年）"
    t.decimal "granted_days", precision: 4, scale: 1, null: false, comment: "付与日数"
    t.decimal "used_days", precision: 4, scale: 1, default: "0.0", comment: "使用済日数"
    t.decimal "expired_days", precision: 4, scale: 1, default: "0.0", comment: "失効日数"
    t.decimal "remaining_days", precision: 4, scale: 1, null: false, comment: "残日数"
    t.integer "fiscal_year", null: false, comment: "対象年度"
    t.string "grant_type", default: "auto", comment: "auto=自動/manual=手動/special=特別"
    t.text "notes", comment: "備考"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["employee_id", "grant_date"], name: "index_paid_leave_grants_on_employee_id_and_grant_date", unique: true
    t.index ["employee_id"], name: "index_paid_leave_grants_on_employee_id"
    t.index ["expiry_date"], name: "index_paid_leave_grants_on_expiry_date"
    t.index ["fiscal_year"], name: "index_paid_leave_grants_on_fiscal_year"
  end

  create_table "paid_leave_requests", force: :cascade do |t|
    t.bigint "employee_id", null: false
    t.date "leave_date", null: false, comment: "取得日"
    t.string "leave_type", null: false, comment: "full/half_am/half_pm"
    t.text "reason", comment: "申請理由"
    t.string "status", default: "pending", comment: "pending/approved/rejected/cancelled"
    t.bigint "approved_by_id"
    t.datetime "approved_at"
    t.text "rejection_reason", comment: "却下理由"
    t.bigint "paid_leave_grant_id"
    t.decimal "consumed_days", precision: 4, scale: 1, null: false, comment: "消化日数"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["approved_by_id"], name: "index_paid_leave_requests_on_approved_by_id"
    t.index ["employee_id", "leave_date"], name: "index_paid_leave_requests_on_employee_id_and_leave_date", unique: true
    t.index ["employee_id"], name: "index_paid_leave_requests_on_employee_id"
    t.index ["leave_date"], name: "index_paid_leave_requests_on_leave_date"
    t.index ["paid_leave_grant_id"], name: "index_paid_leave_requests_on_paid_leave_grant_id"
    t.index ["status"], name: "index_paid_leave_requests_on_status"
  end

  create_table "partners", force: :cascade do |t|
    t.string "code", null: false
    t.string "name", null: false
    t.boolean "has_temporary_employees", default: false
    t.string "offset_rule"
    t.integer "closing_day"
    t.decimal "carryover_balance", precision: 15, scale: 2, default: "0.0"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "payment_terms", force: :cascade do |t|
    t.string "termable_type", null: false
    t.bigint "termable_id", null: false
    t.string "name", null: false
    t.integer "closing_day", null: false
    t.integer "payment_month_offset", default: 1
    t.integer "payment_day", null: false
    t.boolean "is_default", default: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["termable_type", "termable_id", "is_default"], name: "index_payment_terms_on_termable_and_default"
    t.index ["termable_type", "termable_id"], name: "index_payment_terms_on_termable"
    t.index ["termable_type", "termable_id"], name: "index_payment_terms_on_termable_type_and_termable_id"
  end

  create_table "payments", force: :cascade do |t|
    t.bigint "invoice_id", null: false
    t.date "payment_date", null: false
    t.decimal "amount", precision: 15, scale: 2, null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["invoice_id"], name: "index_payments_on_invoice_id"
  end

  create_table "project_assignments", force: :cascade do |t|
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
  end

  create_table "project_cost_templates", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.string "category", null: false
    t.string "item_name", null: false
    t.string "unit"
    t.decimal "unit_price", precision: 12, scale: 2
    t.string "supplier_name"
    t.text "note"
    t.integer "sort_order", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id", "category"], name: "index_project_cost_templates_on_project_id_and_category"
    t.index ["project_id"], name: "index_project_cost_templates_on_project_id"
  end

  create_table "project_documents", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.bigint "uploaded_by_id"
    t.string "name", null: false
    t.string "category", default: "other", null: false
    t.text "description"
    t.date "document_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "drive_file_url"
    t.index ["project_id", "category"], name: "index_project_documents_on_project_id_and_category"
    t.index ["project_id"], name: "index_project_documents_on_project_id"
    t.index ["uploaded_by_id"], name: "index_project_documents_on_uploaded_by_id"
  end

  create_table "project_messages", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.bigint "employee_id", null: false
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["employee_id"], name: "index_project_messages_on_employee_id"
    t.index ["project_id", "created_at"], name: "index_project_messages_on_project_id_and_created_at"
    t.index ["project_id"], name: "index_project_messages_on_project_id"
  end

  create_table "project_monthly_progresses", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.integer "year", null: false
    t.integer "month", null: false
    t.decimal "progress_amount", precision: 12, default: "0"
    t.string "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id", "year", "month"], name: "idx_project_monthly_progress_unique", unique: true
    t.index ["project_id"], name: "index_project_monthly_progresses_on_project_id"
  end

  create_table "project_safety_requirements", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.bigint "safety_document_type_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id", "safety_document_type_id"], name: "idx_project_safety_requirements_unique", unique: true
    t.index ["project_id"], name: "index_project_safety_requirements_on_project_id"
    t.index ["safety_document_type_id"], name: "index_project_safety_requirements_on_safety_document_type_id"
  end

  create_table "projects", force: :cascade do |t|
    t.bigint "client_id"
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
    t.text "estimate_memo"
    t.text "description"
    t.index ["client_id"], name: "index_projects_on_client_id"
    t.index ["construction_user_id"], name: "index_projects_on_construction_user_id"
    t.index ["engineering_user_id"], name: "index_projects_on_engineering_user_id"
    t.index ["project_type"], name: "index_projects_on_project_type"
    t.index ["sales_user_id"], name: "index_projects_on_sales_user_id"
    t.index ["scheduled_end_date"], name: "index_projects_on_scheduled_end_date"
    t.index ["scheduled_start_date"], name: "index_projects_on_scheduled_start_date"
    t.index ["status"], name: "index_projects_on_status"
  end

  create_table "received_invoices", force: :cascade do |t|
    t.bigint "partner_id"
    t.bigint "project_id"
    t.bigint "uploaded_by_id"
    t.bigint "approved_by_id"
    t.string "invoice_number"
    t.string "vendor_name"
    t.date "invoice_date"
    t.date "due_date"
    t.decimal "amount", precision: 12
    t.decimal "tax_amount", precision: 12
    t.string "description"
    t.string "status", default: "pending", null: false
    t.text "rejection_reason"
    t.datetime "approved_at"
    t.datetime "paid_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "client_id"
    t.bigint "accounting_approved_by_id"
    t.datetime "accounting_approved_at"
    t.bigint "sales_approved_by_id"
    t.datetime "sales_approved_at"
    t.bigint "engineering_approved_by_id"
    t.datetime "engineering_approved_at"
    t.index ["accounting_approved_by_id"], name: "index_received_invoices_on_accounting_approved_by_id"
    t.index ["approved_by_id"], name: "index_received_invoices_on_approved_by_id"
    t.index ["client_id"], name: "index_received_invoices_on_client_id"
    t.index ["due_date"], name: "index_received_invoices_on_due_date"
    t.index ["engineering_approved_by_id"], name: "index_received_invoices_on_engineering_approved_by_id"
    t.index ["invoice_date"], name: "index_received_invoices_on_invoice_date"
    t.index ["partner_id"], name: "index_received_invoices_on_partner_id"
    t.index ["project_id"], name: "index_received_invoices_on_project_id"
    t.index ["sales_approved_by_id"], name: "index_received_invoices_on_sales_approved_by_id"
    t.index ["status"], name: "index_received_invoices_on_status"
    t.index ["uploaded_by_id"], name: "index_received_invoices_on_uploaded_by_id"
  end

  create_table "safety_document_types", force: :cascade do |t|
    t.string "name", null: false
    t.string "description"
    t.integer "position", default: 0, null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_safety_document_types_on_active"
    t.index ["position"], name: "index_safety_document_types_on_position"
  end

  create_table "safety_files", force: :cascade do |t|
    t.bigint "safety_folder_id"
    t.string "name", null: false
    t.text "description"
    t.bigint "uploaded_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "project_id"
    t.bigint "safety_document_type_id"
    t.index ["project_id"], name: "index_safety_files_on_project_id"
    t.index ["safety_document_type_id"], name: "index_safety_files_on_safety_document_type_id"
    t.index ["safety_folder_id"], name: "index_safety_files_on_safety_folder_id"
  end

  create_table "safety_folders", force: :cascade do |t|
    t.bigint "project_id"
    t.string "name", null: false
    t.text "description"
    t.integer "files_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_safety_folders_on_project_id"
  end

  create_table "work_schedules", force: :cascade do |t|
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
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "attendances", "daily_reports"
  add_foreign_key "attendances", "employees"
  add_foreign_key "audit_logs", "employees", column: "user_id"
  add_foreign_key "budgets", "projects"
  add_foreign_key "cash_flow_entries", "clients"
  add_foreign_key "cash_flow_entries", "employees", column: "confirmed_by_id"
  add_foreign_key "cash_flow_entries", "partners"
  add_foreign_key "cash_flow_entries", "projects"
  add_foreign_key "cost_breakdown_templates", "employees"
  add_foreign_key "daily_reports", "employees", column: "foreman_id"
  add_foreign_key "daily_reports", "employees", column: "revised_by_id"
  add_foreign_key "daily_reports", "projects"
  add_foreign_key "daily_schedule_notes", "projects"
  add_foreign_key "data_imports", "employees", column: "imported_by_id"
  add_foreign_key "employees", "partners"
  add_foreign_key "estimate_categories", "estimates"
  add_foreign_key "estimate_confirmations", "estimates"
  add_foreign_key "estimate_item_costs", "estimate_items"
  add_foreign_key "estimate_item_templates", "employees"
  add_foreign_key "estimate_items", "estimate_categories"
  add_foreign_key "estimate_items", "estimates"
  add_foreign_key "estimate_templates", "employees"
  add_foreign_key "estimates", "employees", column: "created_by_id"
  add_foreign_key "estimates", "projects"
  add_foreign_key "expenses", "daily_reports"
  add_foreign_key "expenses", "employees", column: "payer_id"
  add_foreign_key "expenses", "employees", column: "processed_by_id"
  add_foreign_key "expenses", "partners", column: "supplier_id"
  add_foreign_key "expenses", "projects"
  add_foreign_key "fixed_expense_monthly_amounts", "fixed_expense_schedules"
  add_foreign_key "invoice_items", "invoices"
  add_foreign_key "invoices", "payment_terms"
  add_foreign_key "invoices", "projects"
  add_foreign_key "monthly_cost_confirmations", "employees", column: "confirmed_by_id"
  add_foreign_key "monthly_outsourcing_costs", "partners"
  add_foreign_key "monthly_outsourcing_costs", "projects"
  add_foreign_key "monthly_progresses", "projects"
  add_foreign_key "monthly_salaries", "employees"
  add_foreign_key "offsets", "partners"
  add_foreign_key "outsourcing_entries", "daily_reports"
  add_foreign_key "outsourcing_entries", "partners"
  add_foreign_key "outsourcing_schedules", "partners"
  add_foreign_key "outsourcing_schedules", "projects"
  add_foreign_key "paid_leave_grants", "employees"
  add_foreign_key "paid_leave_requests", "employees"
  add_foreign_key "paid_leave_requests", "employees", column: "approved_by_id"
  add_foreign_key "paid_leave_requests", "paid_leave_grants"
  add_foreign_key "payments", "invoices"
  add_foreign_key "project_assignments", "employees"
  add_foreign_key "project_assignments", "projects"
  add_foreign_key "project_cost_templates", "projects"
  add_foreign_key "project_documents", "employees", column: "uploaded_by_id"
  add_foreign_key "project_documents", "projects"
  add_foreign_key "project_messages", "employees"
  add_foreign_key "project_messages", "projects"
  add_foreign_key "project_monthly_progresses", "projects"
  add_foreign_key "project_safety_requirements", "projects"
  add_foreign_key "project_safety_requirements", "safety_document_types"
  add_foreign_key "projects", "clients"
  add_foreign_key "received_invoices", "clients"
  add_foreign_key "received_invoices", "employees", column: "accounting_approved_by_id"
  add_foreign_key "received_invoices", "employees", column: "approved_by_id"
  add_foreign_key "received_invoices", "employees", column: "engineering_approved_by_id"
  add_foreign_key "received_invoices", "employees", column: "sales_approved_by_id"
  add_foreign_key "received_invoices", "employees", column: "uploaded_by_id"
  add_foreign_key "received_invoices", "partners"
  add_foreign_key "received_invoices", "projects"
  add_foreign_key "safety_files", "employees", column: "uploaded_by_id"
  add_foreign_key "safety_files", "projects"
  add_foreign_key "safety_files", "safety_document_types"
  add_foreign_key "safety_files", "safety_folders"
  add_foreign_key "safety_folders", "projects"
  add_foreign_key "work_schedules", "employees"
  add_foreign_key "work_schedules", "projects"
end
