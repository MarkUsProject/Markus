# Logging configuration. MarkUs writes its logs with Semantic Logger (see https://logger.reidmorrison.com/rails).
#
# This file is loaded by config/application.rb rather than being an initializer, because Rails creates the logger
# (and the middleware that tags the log entries of each request) before it runs config/initializers.
Markus::Application.configure do
  log_file = File.expand_path(Settings.logging.log_file, config.root)
  FileUtils.mkdir_p(File.dirname(log_file))
  config.semantic_logger.application = 'MarkUs'
  config.rails_semantic_logger.appenders do |appenders|
    appenders.add(file_name: log_file, formatter: Settings.logging.format.to_sym)
    appenders.add_console(formatter: :color)
  end

  # Record the source code location of each database query (and of every other log entry)
  config.semantic_logger.backtrace_level = :debug if Settings.rails.active_record.verbose_query_logs

  # Tag each entry written while handling a request with the client's IP address
  config.log_tags = { ip: :remote_ip }

  if Settings.logging.tag_with_usernames && Settings.rails.session_store.type == 'cookie_store'
    config.log_tags[:user_name] = proc do |request|
      session_info = request.cookie_jar.encrypted[Rails.application.config.session_options[:key]] || {}
      real_user_name = session_info['real_user_name']
      user_name = session_info['user_name']
      if user_name && user_name != real_user_name
        "#{real_user_name} as #{user_name}"
      else
        real_user_name
      end
    end
  end
end
