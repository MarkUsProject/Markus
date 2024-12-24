Markus::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  Rails.application.config.middleware.use ActionDispatch::Session::CookieStore
end
