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
    resources :daily_reports do
      member do
        post :confirm
      end
    end
    resources :invoices do
      member do
        post :issue
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
      get :export_all
    end
  end

  # 全請求書一覧
  resources :all_invoices, only: [:index]

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

  # マスター管理
  namespace :master do
    resources :clients
    resources :partners
    resources :employees
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
