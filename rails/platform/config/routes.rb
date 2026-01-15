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

  # Projects
  resources :projects do
    member do
      post :complete_four_point
    end
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
  end

  # 常用日報（外部現場）
  resources :external_daily_reports, only: %i[index new create show edit update] do
    member do
      post :confirm
    end
  end

  # 全日報一覧
  resources :all_daily_reports, only: [:index]

  # 全請求書一覧
  resources :all_invoices, only: [:index]

  # Offsets (仮社員相殺)
  resources :offsets do
    member do
      post :confirm
    end
  end

  # API routes for n8n integration
  namespace :api do
    namespace :v1 do
      # Data endpoints
      resources :projects, only: %i[index show] do
        collection do
          get :summary
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
