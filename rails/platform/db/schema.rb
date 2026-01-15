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

ActiveRecord::Schema[8.0].define(version: 2026_01_15_043546) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "attendances", force: :cascade do |t|
    t.bigint "tenant_id", null: false
    t.bigint "daily_report_id", null: false
    t.bigint "employee_id", null: false
    t.string "attendance_type", null: false
    t.time "start_time"
    t.time "end_time"
    t.integer "travel_distance"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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

  create_table "daily_reports", force: :cascade do |t|
    t.bigint "tenant_id", null: false
    t.bigint "project_id", null: false
    t.bigint "foreman_id", null: false
    t.date "report_date", null: false
    t.string "weather"
    t.integer "temperature_high"
    t.integer "temperature_low"
    t.text "work_content"
    t.text "notes"
    t.string "status", default: "draft"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["foreman_id"], name: "index_daily_reports_on_foreman_id"
    t.index ["project_id"], name: "index_daily_reports_on_project_id"
    t.index ["tenant_id", "project_id", "report_date"], name: "idx_on_tenant_id_project_id_report_date_7d91023d27", unique: true
    t.index ["tenant_id"], name: "index_daily_reports_on_tenant_id"
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
    t.index ["employment_type"], name: "index_employees_on_employment_type"
    t.index ["partner_id"], name: "index_employees_on_partner_id"
    t.index ["role"], name: "index_employees_on_role"
    t.index ["tenant_id", "code"], name: "index_employees_on_tenant_id_and_code", unique: true
    t.index ["tenant_id", "email"], name: "index_employees_on_tenant_id_and_email", unique: true
    t.index ["tenant_id"], name: "index_employees_on_tenant_id"
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
    t.index ["approved_by_id"], name: "index_expenses_on_approved_by_id"
    t.index ["daily_report_id"], name: "index_expenses_on_daily_report_id"
    t.index ["payer_id"], name: "index_expenses_on_payer_id"
    t.index ["project_id"], name: "index_expenses_on_project_id"
    t.index ["tenant_id"], name: "index_expenses_on_tenant_id"
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
    t.index ["client_id"], name: "index_projects_on_client_id"
    t.index ["construction_user_id"], name: "index_projects_on_construction_user_id"
    t.index ["engineering_user_id"], name: "index_projects_on_engineering_user_id"
    t.index ["sales_user_id"], name: "index_projects_on_sales_user_id"
    t.index ["status"], name: "index_projects_on_status"
    t.index ["tenant_id", "code"], name: "index_projects_on_tenant_id_and_code", unique: true
    t.index ["tenant_id"], name: "index_projects_on_tenant_id"
  end

  create_table "tenants", force: :cascade do |t|
    t.string "code", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_tenants_on_code", unique: true
  end

  add_foreign_key "attendances", "daily_reports"
  add_foreign_key "attendances", "employees"
  add_foreign_key "attendances", "tenants"
  add_foreign_key "audit_logs", "employees", column: "user_id"
  add_foreign_key "audit_logs", "tenants"
  add_foreign_key "budgets", "projects"
  add_foreign_key "budgets", "tenants"
  add_foreign_key "clients", "tenants"
  add_foreign_key "daily_reports", "employees", column: "foreman_id"
  add_foreign_key "daily_reports", "projects"
  add_foreign_key "daily_reports", "tenants"
  add_foreign_key "employees", "partners"
  add_foreign_key "employees", "tenants"
  add_foreign_key "expenses", "daily_reports"
  add_foreign_key "expenses", "employees", column: "payer_id"
  add_foreign_key "expenses", "projects"
  add_foreign_key "expenses", "tenants"
  add_foreign_key "invoices", "projects"
  add_foreign_key "invoices", "tenants"
  add_foreign_key "offsets", "partners"
  add_foreign_key "offsets", "tenants"
  add_foreign_key "partners", "tenants"
  add_foreign_key "payments", "invoices"
  add_foreign_key "payments", "tenants"
  add_foreign_key "projects", "clients"
  add_foreign_key "projects", "tenants"
end
