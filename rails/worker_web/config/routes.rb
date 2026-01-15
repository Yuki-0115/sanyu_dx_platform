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
end
