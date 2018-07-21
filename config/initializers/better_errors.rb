# Configuration for the 'better_errors' gem

if Rails.env.development? && defined?(BetterErrors) && ENV['SSH_CLIENT']
  # Enable better_errors for 0.0.0.0 IP address
  host = ENV['SSH_CLIENT'].match(/\A([^\s]*)/)[1]
  BetterErrors::Middleware.allow_ip! host if host
end
