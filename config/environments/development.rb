Markus::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # In addition to the log file, write logs to standard output when running the rails server
  # or a resque worker (see lib/tasks/resque.rake)
  config.rails_semantic_logger.appenders do |appenders|
    appenders.add_server(formatter: :color)
  end
end
