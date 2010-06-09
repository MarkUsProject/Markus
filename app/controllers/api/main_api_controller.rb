require 'base64'

#=== Description
# Scripting API handlers for MarkUs
module Api

  #===Description
  # This is the parent class of all API controllers.
  # Shared functionality of all API controllers
  # should go here.
  class MainApiController < ActionController::Base

    before_filter :authenticate

    #=== Description
    # Dummy action (for authentication testing)
    # No public route matches this action.
    def index
      render :file => "#{RAILS_ROOT}/public/200.xml", :status => 200
    end

    private
    #=== Description
    # Auth handler for the MarkUs API. It uses
    # the Authorization HTTP header to determine
    # the user who issued the request. With the Authorization
    # HTTP header comes a Base 64 encoded MD5 digest of the
    # user's private key.
    def authenticate
      auth_token = parse_auth_token(request.headers["HTTP_AUTHORIZATION"])
      # pretend resource not found if missing or wrong authentication
      # is provided
      if auth_token.nil?
        render :file => "#{RAILS_ROOT}/public/403.xml", :status => 403
        return
      end
      # Find user by api_key_md5
      @current_user = User.find_by_api_key(auth_token)
      if @current_user.nil?
        # Key does not exist, so bail out
        render :file => "#{RAILS_ROOT}/public/403.xml", :status => 403
        return
      else
        # see if the MD5 matches
        curr_user_md5 = Base64.decode64(@current_user.api_key)
        if (Base64.decode64(auth_token) != curr_user_md5)
          # MD5 mismatch, bail out
          render :file => "#{RAILS_ROOT}/public/403.xml", :status => 403
          return
        end
      end
      # Student's aren't allowed yet
      if @current_user.student?
        # API is available for TAs and Admins only
        render :file => "#{RAILS_ROOT}/public/403.xml", :status => 403
        return
      end
    end


    #=== Description
    # Helper method for parsing the authentication token
    def parse_auth_token(token)
      return nil if token.nil?
      if !(token =~ /MarkUsAuth ([^\s,]+)/).nil?
        return $1 # return matched part
      else
        return nil
      end
    end

  end

end # end Api module
