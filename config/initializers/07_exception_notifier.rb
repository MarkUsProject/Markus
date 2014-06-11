Markus::Application.config.middleware.use(
  ExceptionNotification::Rack,
  email: {
    # Set the name of the MarkUs instance here
    email_prefix: '[MarkUs - Exception Notifier] ',
    sender_address: %{"Exception Notifier" <support@example.com>},
    exception_recipients: %w(you@me.com)
  })
