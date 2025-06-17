# Redis configuration
REDIS_URL = ENV.fetch('REDIS_URL', 'redis://redis:6379/0')

$redis = Redis.new(url: REDIS_URL)

# Test Redis connection
begin
  $redis.ping
  Rails.logger.info "Redis connection established successfully"
rescue Redis::CannotConnectError => e
  Rails.logger.error "Failed to connect to Redis: #{e.message}"
end
