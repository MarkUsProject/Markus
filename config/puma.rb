workers 3
preload_app!

rails_env = environment ENV.fetch('RAILS_ENV') { 'development' }
if rails_env == 'development'
  worker_timeout 100_000_000
end

on_worker_boot do
  ActiveSupport.on_load(:active_record) do
    ActiveRecord::Base.establish_connection
  end
  Resque.redis.reconnect
end
