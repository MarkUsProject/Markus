# detects if cookies are enabled in the user's browser, by attempting to read/write a cookie.

module CookieDetection

  protected

  # true if cookies are enabled, false otherwise.
  def cookies_enabled
    if cookies[:cookieTest].blank?
      if params[:cookieTest].nil?
        cookies[:cookieTest] = Time.now
        redirect_to :controller => "main", :action => "login", :cookieTest => "testing"
      else
        return false
      end
   else
     return true
   end 
  end
end