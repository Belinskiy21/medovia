Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      resource :session, only: [ :create ]

      resources :healthcare_units, only: [ :index, :show ] do
        resources :medications, only: [ :index, :create ]
        resources :orders, only: [ :index, :create ]
        get "orders_export", to: "orders#export"
      end

      resources :medications, only: [ :show, :update, :destroy ]
      resources :orders, only: [ :show ] do
        patch :advance, on: :member
      end
      resources :audit_logs, only: [ :index ]
    end
  end
end
