require 'resque/server'
require 'resque-scheduler'
require 'resque/scheduler/server'

Resque.redis = Settings.redis.url

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
