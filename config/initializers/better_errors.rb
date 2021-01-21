# Configuration for the 'better_errors' gem

if Rails.env.development? && defined?(BetterErrors)
  # Enable better_errors for 0.0.0.0 IP address
  host = ENV['SSH_CLIENT']&.match(/\A([^\s]*)/)&.second
  BetterErrors::Middleware.allow_ip! host if host
  BetterErrors::Middleware.allow_ip! '0.0.0.0/0'
end
