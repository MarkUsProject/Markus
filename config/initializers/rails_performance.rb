require 'rails_performance'

Rails.application.config.after_initialize do
  if defined?(RailsPerformance)
    # Modify CSP for Performance Gem
    RailsPerformance::RailsPerformanceController.class_eval do
      include SessionHandler

      content_security_policy do |p|
        p.style_src :self, "'unsafe-inline'"
        p.script_src_elem :self,
                          "'unsafe-inline'",
                          'https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.12.1/js/all.min.js',
                          'https://code.highcharts.com'
      end
    end

    RailsPerformance.setup do |config|
      config.enabled = true
      config.redis = Redis::Namespace.new(Rails.root.to_s)
      config.duration = Settings.session_timeout.seconds
      # default path where to mount gem
      config.mount_at = '/admin/performance'
      config.verify_access_proc = proc { @real_user&.admin_user? }
    end
  end
end
