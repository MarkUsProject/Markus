# Modify PgHero::Engine class to add (manual) authentication
Rails.application.config.after_initialize do
  PgHero::HomeController.class_eval do
    include SessionHandler

    before_action :check_user_not_authorized

    protected

    # Helper to use SessionHandler to check for permissions
    def check_user_not_authorized
      unless real_user.present? && real_user.admin_user?
        render 'shared/http_status',
               formats: [:html], locals: { code: '403', message: HttpStatusHelper::ERROR_CODE['message']['403'] },
               status: :forbidden, layout: false
      end
    end
  end
end
