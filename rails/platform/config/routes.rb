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

  # 現場カレンダー
  get "schedule", to: "schedule#index", as: :schedule
  get "schedule/project_assignments/:project_id", to: "schedule#project_assignments", as: :schedule_project_assignments

  # Projects
  resources :projects do
    member do
      post :complete_four_point
      post :complete_pre_construction_gate
      post :start_construction
    end
    resources :project_assignments, only: %i[create destroy], as: :assignments
    resource :estimate, only: %i[show new create edit update] do
      post :approve
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

  # マスター管理
  namespace :master do
    resources :clients
    resources :partners
    resources :employees
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
