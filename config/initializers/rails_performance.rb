require 'rails_performance'

Rails.application.config.after_initialize do
  if Settings.rails_performance.enabled
    RailsPerformance::RailsPerformanceController.class_eval do
      include SessionHandler

      before_action :check_user_not_authorized

      # Modify CSP for Performance Gem
      content_security_policy do |p|
        p.style_src :self, "'unsafe-inline'"
        p.script_src_elem :self,
                          "'unsafe-inline'",
                          'https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.12.1/js/all.min.js',
                          'https://code.highcharts.com'
      end

      protected

      # Helper to use SessionHandler to check for permissions
      def check_user_not_authorized
        unless real_user&.admin_user?
          render 'shared/http_status',
                 formats: [:html], locals: { code: '403', message: HttpStatusHelper::ERROR_CODE['message']['403'] },
                 status: :forbidden, layout: false
        end
      end
    end
  end

  if defined?(RailsPerformance)
    RailsPerformance.setup do |config|
      config.enabled = Settings.rails_performance.enabled
      config.duration = Settings.rails_performance.duration.minutes
      config.home_link = ENV.fetch('RAILS_RELATIVE_URL_ROOT') { '/' }
      config.mount_at = '/admin/rails/performance'
      config.redis = Redis::Namespace.new("#{Rails.env}-rails-performance", redis: Resque.redis)
    end
  end
end
