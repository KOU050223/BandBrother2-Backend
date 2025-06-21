# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin Ajax requests.

# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  # フロントエンド用の設定（credentials有効）
  allow do
    origins 'localhost:3000', 'localhost:5173', '127.0.0.1:3000', '127.0.0.1:5173',
            'https://bandbrother2-2764c.web.app',
            'https://bandbrother2-2764c.firebaseapp.com',
            /https:\/\/.*\.vercel\.app$/,  # Vercel deployments
            /https:\/\/.*\.netlify\.app$/,  # Netlify deployments  
            /https:\/\/.*\.firebaseapp\.com$/,  # Firebase deployments
            /https:\/\/.*\.web\.app$/,       # Firebase web apps
            %r{\Ahttps://game-server-[\w-]+\.a\.run\.app\z},
            %r{\Ahttps://rails-server-[\w-]+\.a\.run\.app\z},
            /https:\/\/.*\.a\.run\.app$/
    resource '*',
      headers: :any,
      methods: %i[get post delete options],
      credentials: true
  end

  # 全オリジン許可（credentials無効、内部通信用）
  allow do
    origins '*'
    
    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: false
  end
end
