module Rack
  class Attack
    # Throttle login POST requests by both username and IP address.
    #
    # Rack::Attack combines this throttle name, the current period, and the
    # discriminator returned below when building its cache key.
    #
    throttle('login/user+ip', limit: 5, period: 1.minute) do |request|
      username = request.params['user_login'].to_s.strip
      password = request.params['user_password'].to_s
      login_request = request.post? &&
                      request.path_info == '/' &&
                      username.present? &&
                      password.present?

      if login_request
        "#{request.ip}:#{username.downcase}"
      end
    end
  end
end
