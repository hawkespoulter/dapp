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
      get '/game_content', to: 'game_content#index'
      resources :bug_reports, only: %i[index create update destroy]
      get '/game_content/export', to: 'game_content#export'
      post '/challenges', to: 'game_content#create_challenge'
      patch '/challenges/:id', to: 'game_content#update_challenge'
      delete '/challenges/:id', to: 'game_content#destroy_challenge'
      post '/claim_challenges', to: 'game_content#create_claim'
      patch '/claim_challenges/:id', to: 'game_content#update_claim'
      delete '/claim_challenges/:id', to: 'game_content#destroy_claim'
      post '/challenge_lists', to: 'game_content#create_list'
      patch '/challenge_lists/:id', to: 'game_content#update_list'
      delete '/challenge_lists/:id', to: 'game_content#destroy_list'
      resources :game_settings, only: %i[ index update ], param: :key do
        post :reset, on: :member
      end
      resources :games, only: %i[ create show ], param: :code do
        member do
          post :join
          post :start
          post :complete
          post :fail, action: :fail_challenge
          post :skip
          post :undo
          post :place
          post :villain_turn
          post :abandon
          post :power
          post :forecast
          patch :balance
          post :claim
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
