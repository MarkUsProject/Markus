module Rack
  class Attack
    # Throttle login POST requests by both username and IP address.
    #
    # Rack::Attack combines this throttle name, the current period, and the
    # discriminator returned below when building its cache key.
    #
    throttle('login/user+ip', limit: 5, period: 1.minute) do |request|
      if request.post? && request.path == '/'
        username = request.params['user_login'].to_s.strip.downcase
        "#{request.ip}:#{username}"
      end
    end
  end
end
