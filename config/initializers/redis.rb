Redis.current = Redis.new(url: Settings.redis.url)
Resque.redis = Redis.current
RailsPerformance.redis = Redis::Namespace.new("#{Rails.env}-rails-performance", redis: Redis.current)
