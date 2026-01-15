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
    resource :budget, only: %i[show new create edit update] do
      post :confirm
    end
  end

  # API routes (for future use)
  # namespace :api do
  #   namespace :v1 do
  #   end
  # end
end
