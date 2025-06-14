Rails.application.routes.draw do
  POST "scores/create"
  get "match_notification/notify_match"
  get "match_making/join"
  get "match_making/destroy"
  get "users/create"
  get "users/show"
  # get "music/index"
  # get "music/show"
  # # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # # Can be used by load balancers and uptime monitors to verify that the app is live.
  # get "up" => "rails/health#show", as: :rails_health_check

  # # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # # Defines the root path route ("/")
  # # root "posts#index"

    namespace :api do

    # 楽曲データ取得
      resources :music, only: [:index, :show]
    #スコアデータ送信
      post ':game_id/score', to: 'scores#create'
    #roomマッチング
      post 'matchmaking/join', to: 'matchmaking#join'
    #
    #
    #
    #
    end
end
