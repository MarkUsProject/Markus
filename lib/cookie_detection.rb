# detects if cookies are enabled in the user's browser, by attempting to read/write a cookie.

module CookieDetection

  protected

  # true if cookies are enabled, false otherwise.
  def cookies_enabled
    return true unless cookies["cookieTest"].blank?
    cookies["cookieTest"] = Time.now
    session[:return_to] = request.fullpath
    if cookies["cookie_test"].blank?
      return false
    end
    return true
  end
end