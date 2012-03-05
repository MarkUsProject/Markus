# detects if cookies are enabled in the user's browser, by attempting to read/write a cookie.

module CookieDetection

  protected

  # true if cookies are enabled, false otherwise.
  def cookies_enabled(*wasEmpty)
    debugger
    if cookies[:cookieTest].blank?
      if wasEmpty.empty?
        cookies[:cookieTest] = Time.now
        cookies_enabled("testing")
      else
        return false
      end
   else
     return true
   end 
   #   return true
   # else  
   #   cookies_enabled(true)
   # end if
   # if(wasEmpty[0])
   #   return false
   # else
   #   return true
   # end if
   # cookies[:cookieTest] = Time.now
   # session[:return_to] = request.fullpath
   # if cookies[:cookieTest].blank?
   #   return false
   # end
   # return true
  end
end