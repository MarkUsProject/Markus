Redis.current = Redis.new(url: Settings.redis.url)
Resque.redis = Redis.current
