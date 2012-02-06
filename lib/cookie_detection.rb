# detects if cookies are enabled in the user's browser, by attempting to reading/writing a cookie.

module CookieDetection
 
protected
 
  # checks for presence of "cookie_test" cookie.
  # If not present, redirects to cookies_test action
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