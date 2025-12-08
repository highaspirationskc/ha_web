Rails.application.routes.draw do
  # if Rails.env.development?
  mount GraphiQL::Rails::Engine, at: "/graphiql", graphql_path: "/graphql"
  # end
  post "/graphql", to: "graphql#execute"

  # Email confirmation
  get "confirm/:token", to: "confirmations#confirm", as: :confirmation

  # Authentication
  get "login", to: "sessions#new"
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy"
  get "dashboard", to: "dashboard#index"

  # User spoofing (admin only)
  post "spoof/:user_id", to: "spoof#create", as: :spoof
  delete "spoof", to: "spoof#destroy", as: :unspoof

  resources :users do
    member do
      patch :activate
      patch :deactivate
      post :add_family_member
      delete :remove_family_member
      post :create_guardian
      post :add_mentee
      delete :remove_mentee
    end
  end

  resources :mentees
  resources :events
  resources :event_types
  resources :event_registrations
  resources :event_logs
  resources :teams do
    member do
      post :add_member
      delete :remove_member
    end
  end
  resources :olympic_seasons
  resources :family_members

  # Messaging
  resources :messages, only: [:index, :show, :new, :create] do
    member do
      post :archive
      post :unarchive
    end
    collection do
      get :sent
      get :archived
      get :support
    end
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "sessions#new"
end
