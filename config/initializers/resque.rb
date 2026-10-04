require 'resque/server'
require 'resque-scheduler'
require 'resque/scheduler/server'

if Rails.env.test?
  worker_id = ENV.fetch('TEST_ENV_NUMBER', '')
  Resque.redis = Redis::Namespace.new("test#{worker_id}", redis: Redis.new(url: Settings.redis.url))
else
  Resque.redis = Settings.redis.url
end

# rails_semantic_logger replaces Resque.logger. Only write warnings and errors logged by resque itself,
# since Active Job already logs when each job is performed.
Resque.logger.level = :warn

# Modify Resque::Server class to add (manual) authentication
unless ENV['NO_INIT_SCHEDULER']
  Rails.application.config.after_initialize do
    Resque::Server.class_eval do
      include SessionHandler

      set :host_authorization, { permitted_hosts: Settings.resque.permitted_hosts }

      before do
        unless real_user&.admin_user?
          halt 403, I18n.t(:forbidden)
        end
      end
    end
  end

  Resque.schedule = Settings.resque_scheduler.to_h.deep_stringify_keys
  Resque::Scheduler.dynamic = true
end
