require 'resque/server'
require 'resque-scheduler'
require 'resque/scheduler/server'

# Modify Resque::Server class to add (manual) authentication
Rails.application.config.after_initialize do
  Resque::Server.class_eval do
    include SessionHandler

    before do
      unless real_user&.admin_user?
        halt 403, I18n.t(:forbidden)
      end
    end
  end
end

Resque.schedule = Settings.resque_scheduler.to_h.deep_stringify_keys
