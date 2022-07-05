Redis.silence_deprecations = true
redis = Redis.new(url: Settings.redis.url)
Resque.redis = redis
RailsPerformance.redis = Redis::Namespace.new("#{Rails.env}-rails-performance", redis: redis)
