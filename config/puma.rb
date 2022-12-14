workers Settings.puma.workers
threads Settings.puma.min_threads, Settings.puma.max_threads
worker_timeout Settings.puma.worker_timeout

preload_app!

on_worker_boot do
  ActiveSupport.on_load(:active_record) do
    ActiveRecord::Base.establish_connection
  end
  Resque.redis.reconnect
end
