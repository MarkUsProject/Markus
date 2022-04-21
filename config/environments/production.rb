Markus::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb
  if Settings.exception_notification.enabled
    Rails.application.config.middleware.use ExceptionNotification::Rack,
                                            email: {
                                              email_prefix: '[ERROR] ',
                                              sender_address: %("MarkUs Exception Notifier"
                                                                <#{Settings.exception_notification.sender}>),
                                              exception_recipients: Settings.exception_notification.recipients
                                            }
  end
end
