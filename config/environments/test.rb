Markus::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb
  config.eager_load = true if ENV['CI'].present?
end
