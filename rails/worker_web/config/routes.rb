# frozen_string_literal: true

Rails.application.routes.draw do
  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Authentication
  get "login", to: "sessions#new"
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy"

  # Dashboard (root)
  root "dashboard#index"

  # My attendance records
  resources :attendances, only: [:index]

  # My project assignments
  resources :assignments, only: [:index]

  # Schedule (read-only)
  resources :schedule, only: [:index]

  # Daily Reports
  resources :daily_reports, only: [:index, :new, :create, :show, :edit, :update] do
    member do
      patch :confirm
    end
  end

  # Paid Leave Requests
  resources :paid_leave_requests, only: [:index, :new, :create] do
    member do
      patch :cancel
    end
  end
end
