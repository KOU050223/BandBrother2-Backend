# Redis configuration
REDIS_URL = ENV.fetch('REDIS_URL', 'redis://redis:6379/0')

# 簡単なRedis接続設定
$redis = Redis.new(url: REDIS_URL)

# Rails起動時には接続テストを行わない（遅延ロード）
Rails.logger.info "Redis configured with URL: #{REDIS_URL.gsub(/:[^@]*@/, ':***@')}"
