Rails.application.routes.draw do
  # Devise routes for Employee authentication
  devise_for :employees, path: "auth", path_names: {
    sign_in: "login",
    sign_out: "logout"
  }

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Dashboard (root)
  root "dashboard#index"

  # 経営ダッシュボード
  get "management", to: "management_dashboard#index", as: :management_dashboard

  # 月次損益
  get "monthly_profit_losses", to: "monthly_profit_losses#index", as: :monthly_profit_losses
  get "monthly_profit_losses/yearly", to: "monthly_profit_losses#yearly", as: :yearly_profit_losses
  get "monthly_profit_losses/yearly/:fiscal_year", to: "monthly_profit_losses#yearly", as: :fiscal_year_profit_losses
  get "monthly_profit_losses/trend", to: "monthly_profit_losses#trend", as: :trend_profit_losses
  get "monthly_profit_losses/trend/:fiscal_year", to: "monthly_profit_losses#trend", as: :fiscal_year_trend_profit_losses
  get "monthly_profit_losses/comparison", to: "monthly_profit_losses#comparison", as: :comparison_profit_losses
  get "monthly_profit_losses/comparison/:fiscal_year", to: "monthly_profit_losses#comparison", as: :fiscal_year_comparison_profit_losses
  get "monthly_profit_losses/:year/:month", to: "monthly_profit_losses#show", as: :monthly_profit_loss
  post "monthly_profit_losses/:year/:month/confirm_cost", to: "monthly_profit_losses#confirm_cost", as: :confirm_monthly_cost
  delete "monthly_profit_losses/:year/:month/unconfirm_cost", to: "monthly_profit_losses#unconfirm_cost", as: :unconfirm_monthly_cost

  # 月次確定給与
  get "monthly_salaries/:year/:month", to: "monthly_salaries#index", as: :monthly_salaries
  patch "monthly_salaries/:year/:month", to: "monthly_salaries#bulk_update", as: :bulk_update_monthly_salaries

  # 月次確定外注費
  get "monthly_outsourcing_costs/:year/:month", to: "monthly_outsourcing_costs#index", as: :monthly_outsourcing_costs
  post "monthly_outsourcing_costs/:year/:month/confirm", to: "monthly_outsourcing_costs#confirm_single", as: :confirm_monthly_outsourcing_cost
  delete "monthly_outsourcing_costs/:year/:month/unconfirm", to: "monthly_outsourcing_costs#unconfirm_single", as: :unconfirm_monthly_outsourcing_cost

  # 月次出来高
  get "monthly_progresses/:year/:month", to: "monthly_progresses#index", as: :monthly_progresses
  patch "monthly_progresses/:year/:month", to: "monthly_progresses#bulk_update", as: :bulk_update_monthly_progresses
  post "monthly_progresses/:year/:month/copy_from_previous", to: "monthly_progresses#copy_from_previous", as: :copy_from_previous_monthly_progresses
  patch "projects/:project_id/progress", to: "monthly_progresses#update_for_project", as: :update_project_progress

  # 月次固定費（現場）
  get "monthly_fixed_costs/:year/:month", to: "monthly_fixed_costs#index", as: :monthly_fixed_costs
  get "monthly_fixed_costs/:year/:month/new", to: "monthly_fixed_costs#new", as: :new_monthly_fixed_cost
  post "monthly_fixed_costs/:year/:month", to: "monthly_fixed_costs#create"
  get "monthly_fixed_costs/:year/:month/:id/edit", to: "monthly_fixed_costs#edit", as: :edit_monthly_fixed_cost
  patch "monthly_fixed_costs/:year/:month/:id", to: "monthly_fixed_costs#update", as: :monthly_fixed_cost
  delete "monthly_fixed_costs/:year/:month/:id", to: "monthly_fixed_costs#destroy"
  post "monthly_fixed_costs/:year/:month/copy_from_previous", to: "monthly_fixed_costs#copy_from_previous", as: :copy_from_previous_monthly_fixed_costs

  # 販管費（第1層）
  get "monthly_admin_expenses/:year/:month", to: "monthly_admin_expenses#index", as: :monthly_admin_expenses
  get "monthly_admin_expenses/:year/:month/new", to: "monthly_admin_expenses#new", as: :new_monthly_admin_expense
  post "monthly_admin_expenses/:year/:month", to: "monthly_admin_expenses#create"
  get "monthly_admin_expenses/:year/:month/:id/edit", to: "monthly_admin_expenses#edit", as: :edit_monthly_admin_expense
  patch "monthly_admin_expenses/:year/:month/:id", to: "monthly_admin_expenses#update", as: :monthly_admin_expense
  delete "monthly_admin_expenses/:year/:month/:id", to: "monthly_admin_expenses#destroy"
  post "monthly_admin_expenses/:year/:month/copy_from_previous", to: "monthly_admin_expenses#copy_from_previous", as: :copy_from_previous_monthly_admin_expenses
  post "monthly_admin_expenses/:year/:month/bulk_create", to: "monthly_admin_expenses#bulk_create", as: :bulk_create_monthly_admin_expenses

  # 月次損益計算書（第1層：会計形式）
  get "monthly_income_statements/:year/:month", to: "monthly_income_statements#show", as: :monthly_income_statement

  # 段取り表（dandori_controller対応）
  get "schedule", to: "schedule#index", as: :schedule
  # セル操作
  get "schedule/cell_data", to: "schedule#cell_data", as: :schedule_cell_data
  post "schedule/save_cell", to: "schedule#save_cell", as: :schedule_save_cell
  # 案件別配置取得
  get "schedule/project_assignments/:id", to: "schedule#project_assignments", as: :schedule_project_assignments
  # 一括配置
  post "schedule/bulk_assign", to: "schedule#bulk_assign", as: :schedule_bulk_assign
  # 配置解除
  delete "schedule/remove_assignment/:id", to: "schedule#remove_assignment", as: :schedule_remove_assignment
  # 残り人員
  get "schedule/remaining_workers", to: "schedule#remaining_workers", as: :schedule_remaining_workers
  get "schedule/employee_schedule/available", to: "schedule#available_workers", as: :schedule_available_workers
  # 備考（DailyScheduleNote）
  get "schedule/schedule_note", to: "schedule#schedule_note", as: :schedule_note
  post "schedule/save_schedule_note", to: "schedule#save_schedule_note", as: :save_schedule_note

  # Projects
  resources :projects do
    member do
      post :complete_four_point
      post :complete_pre_construction_gate
      post :start_construction
    end
    resources :project_assignments, only: %i[create destroy], as: :assignments
    resources :estimates do
      member do
        post :approve
        get :pdf
      end
    end
    resource :budget, only: %i[show new create edit update] do
      post :confirm
      post :import_from_estimate
    end
    resource :site_ledger, only: [:show]
    resources :outsourcing_reports, only: %i[index new create]
    resources :daily_reports do
      member do
        post :confirm
      end
    end
    resources :invoices do
      member do
        post :issue
        get :pdf
      end
      resources :payments, only: %i[new create destroy]
    end
    # 書類ファイリング
    resources :project_documents, only: %i[index new create destroy], path: "documents"
  end

  # 常用日報（外部現場）
  resources :external_daily_reports, only: %i[index new create show edit update] do
    member do
      post :confirm
    end
  end

  # 全日報一覧
  resources :all_daily_reports, only: [:index, :new]

  # 勤怠管理表
  resources :attendance_sheets, only: [:index] do
    collection do
      get "employee/:employee_id", action: :employee_detail, as: :employee_detail
      get "employee/:employee_id/export", action: :export_employee, as: :export_employee
      patch "employee/:employee_id/salary", action: :update_salary, as: :update_employee_salary
      get :export_all
      get "project/:project_id", action: :project_detail, as: :project_detail
      get "project/:project_id/export", action: :export_project, as: :export_project
    end
  end

  # 全請求書一覧
  resources :all_invoices, only: [:index]

  # 経費報告（日報外）
  resources :expense_reports, only: %i[index new create show edit update destroy]

  # 仮経費確定
  resources :provisional_expenses, only: [:index] do
    member do
      patch :confirm_fuel
      patch :confirm_highway
    end
    collection do
      post :bulk_confirm_fuel
    end
  end

  # 資金繰り表
  get "cash_flow_calendar", to: "cash_flow_calendar#index", as: :cash_flow_calendar
  get "cash_flow_calendar/:date", to: "cash_flow_calendar#show", as: :cash_flow_date,
      constraints: { date: /\d{4}-\d{2}-\d{2}/ }
  post "cash_flow_calendar/generate", to: "cash_flow_calendar#generate_entries", as: :generate_cash_flow_entries
  patch "cash_flow_entries/:id/confirm", to: "cash_flow_calendar#confirm", as: :confirm_cash_flow_entry
  patch "cash_flow_entries/:id", to: "cash_flow_calendar#update_entry", as: :cash_flow_entry

  # マスター管理
  namespace :master do
    resources :clients
    resources :partners
    resources :employees
    resources :payment_terms, except: [:show]
    resources :fixed_expense_schedules, except: [:show]
    resources :company_holidays, only: [:index, :create, :destroy] do
      collection do
        post :add_holiday
        post :add_weekends
        post :add_national_holidays
        delete :remove_holiday
        post :copy_calendar
        post :bulk_set
        post :copy_from
        post :toggle
      end
    end
    resources :company_events, only: [:index, :create, :update, :destroy]
  end

  # Offsets (仮社員相殺)
  resources :offsets do
    member do
      post :confirm
    end
  end

  # 経理処理（freee/MoneyForward連携）
  namespace :accounting do
    resources :expenses, only: %i[index show] do
      member do
        post :process_expense
        post :reimburse
      end
      collection do
        get :processed
        post :bulk_process
        post :bulk_reimburse
        post :confirm_supplier
        get :export
      end
    end

    # 立替精算管理
    resources :reimbursements, only: %i[index show] do
      member do
        post :reimburse
      end
      collection do
        post :bulk_reimburse
        get :reimbursed
      end
    end
  end

  # 月次帳票
  resources :monthly_reports, only: [:index] do
    collection do
      post :generate
      get :download_cost_report
      get :download_profit_report
      get :download_expense_report
    end
  end

  # 安全書類管理（フォルダ形式）
  resources :safety_documents, only: %i[index show] do
    collection do
      get :new_folder
      post :create_folder
    end
    member do
      get :edit_folder
      patch :update_folder
      delete :destroy_folder
    end
  end
  # 安全書類ファイル
  resources :safety_files, only: [] do
    collection do
      get :new, action: :new_file, as: :new
      post :create, action: :create_file
    end
  end
  get "safety_folders/:folder_id/files/new", to: "safety_documents#new_file", as: :new_safety_folder_file
  post "safety_folders/:folder_id/files", to: "safety_documents#create_file", as: :safety_folder_files
  get "safety_files/:id/edit", to: "safety_documents#edit_file", as: :edit_safety_file
  patch "safety_files/:id", to: "safety_documents#update_file", as: :safety_file
  delete "safety_files/:id", to: "safety_documents#destroy_file"

  # API routes for n8n integration
  namespace :api do
    namespace :v1 do
      # Data endpoints
      resources :projects, only: %i[index show] do
        collection do
          get :summary
        end
        member do
          get :assignments
        end
      end
      resources :daily_reports, only: %i[index show] do
        collection do
          get :unconfirmed
        end
      end

      # Webhook endpoints (called by n8n for notifications)
      post "webhooks/project_created", to: "webhooks#project_created"
      post "webhooks/four_point_completed", to: "webhooks#four_point_completed"
      post "webhooks/budget_confirmed", to: "webhooks#budget_confirmed"
      post "webhooks/daily_report_submitted", to: "webhooks#daily_report_submitted"
      post "webhooks/offset_confirmed", to: "webhooks#offset_confirmed"
    end
  end
end
