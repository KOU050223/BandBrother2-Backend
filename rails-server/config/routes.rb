Rails.application.routes.draw do
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

    namespace :api , defaults: { format: :json } do

    # 楽曲データ取得
      resources :music, only: [:index, :show]
    #スコアデータ送信
      post ':game_id/score', to: 'scores#create'
    #roomマッチング
      post 'matchmaking/join', to: 'matchmaking#join'
    #マッチ成立後の処理
      post 'notify_match', to: 'match_notification#notify_match'
    #ユーザー登録関係
      post 'users', to: 'users#create' # create_or_update はカスタムアクション名
      get 'users', to: 'users#update' # GET /api/user/:id の show
      put 'users', to: 'users#update' # PUT /api/user/:id の update
    #マッチメイキングキャンセル
      delete 'matchmaking', to: 'matchmaking#destroy'
    #スコア送信関係
      post 'scores', to: 'scores#create' # スコア送信
      get 'scores/:id', to: 'scores#show' # スコア取得

    end
end
