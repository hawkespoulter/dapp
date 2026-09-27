Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      get '/park_completion', to: 'api#park_completion'
      get '/date_generator', to: 'api#date_generator'
      get '/completed_areas', to: 'api#completed_areas'
      get '/experience_completion', to: 'api#experience_completion'
      get '/animation_check_list', to: 'api#animation_check_list'

      resources :attractions
      resources :restaurants
      resources :shows

      get '/game_parks', to: 'games#parks'
      get '/finished_games', to: 'game_settings#finished'
      resources :game_settings, only: %i[ index update ], param: :key do
        post :reset, on: :member
      end
      resources :games, only: %i[ create show ], param: :code do
        member do
          post :join
          post :start
          post :complete
          post :fail, action: :fail_challenge
          post :undo
          post :buy
          post :place
          post :villain_turn
          post :power
          post :forecast
        end
      end
    end
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end
