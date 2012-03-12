# detects if cookies are enabled in the user's browser, by attempting to read/write a cookie.

module CookieDetection

  protected

  # true if cookies are enabled, false otherwise.
  def cookies_enabled
    if cookies[:cookieTest].blank?
      if params[:cookieTest].nil?
        cookies[:cookieTest] = Time.now
        # we need to redirect in order to test, otherwise cookies[] will not be blank even if no actual cookie exists because cookies[] was set locally
        # send a parameter, "currentlyTesting" to same controller, and attempt to write cookie again
        redirect_to :controller => "main", :action => "login", :cookieTest => "currentlyTesting"
      else
        # if the parameter cookieTest is set, then we have already tried to write a cookie and it is still empty. Cookies are off.
        return false
      end
   else
     return true
   end
  end
end