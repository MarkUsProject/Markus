# The reconnect_attempts list in config/cable.yml is read by ActionCable's Redis
# subscription listener, which uses it to keep retrying (for ~19 minutes) after
# Redis drops its pub/sub connection. ActionCable also passes the same option to
# every Redis connection it opens, including the one used to publish
# broadcasts. A broadcast attempted while Redis is down would then block the
# calling thread (a Puma thread, for broadcasts made from controllers) for the
# whole retry window. Build those connections with a single quick retry instead,
# so publishing fails fast while the listener keeps its long retry schedule.
ActionCable::SubscriptionAdapter::Redis.redis_connector = ->(config) do
  Redis.new(config.except(:adapter, :channel_prefix).merge(reconnect_attempts: 1))
end
