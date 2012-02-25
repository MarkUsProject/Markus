require 'base64'

#=== Description
# Scripting API handlers for MarkUs
module Api

  #===Description
  # This is the parent class of all API controllers.
  # Shared functionality of all API controllers
  # should go here.
  class MainApiController < ActionController::Base

    before_filter :check_format
    before_filter :authenticate

    #=== Description
    # Dummy action (for authentication testing)
    # No public route matches this action.
    def index
      render 'shared/http_status', :locals => { :code => "200", :message => HttpStatusHelper::ERROR_CODE["message"]["200"] }, :status => 200
    end

    private
    #=== Description
    # Auth handler for the MarkUs API. It uses
    # the Authorization HTTP header to determine
    # the user who issued the request. With the Authorization
    # HTTP header comes a Base 64 encoded MD5 digest of the
    # user's private key.
    def authenticate
      if MarkusConfigurator.markus_config_remote_user_auth
        # Check if authentication was already done and REMOTE_USER was set
        markus_auth_remote_user = request.env["HTTP_X_FORWARDED_USER"]
        if !markus_auth_remote_user.blank?
          # REMOTE_USER authentication used, find the user and bypass regular auth
          @current_user = User.find_by_user_name(markus_auth_remote_user)
        else
          # REMOTE_USER_AUTH is true, but REMOTE_USER wasn't set, bail out
          render 'shared/http_status', :locals => { :code => "403", :message => HttpStatusHelper::ERROR_CODE["message"]["403"] }, :status => 403
          return
        end
      else
        # REMOTE_USER authentication not used, proceed with regular auth
        auth_token = parse_auth_token(request.headers["HTTP_AUTHORIZATION"])
        # pretend resource not found if missing or wrong authentication
        # is provided
        if auth_token.nil?
          render 'shared/http_status', :locals => { :code => "403", :message => HttpStatusHelper::ERROR_CODE["message"]["403"] }, :status => 403
          return
        end
        # Find user by api_key_md5
        @current_user = User.find_by_api_key(auth_token)
      end

      if @current_user.nil?
        # Key/username does not exist, so bail out
        render 'shared/http_status', :locals => { :code => "403", :message => HttpStatusHelper::ERROR_CODE["message"]["403"] }, :status => 403
        return
      elsif markus_auth_remote_user.blank?
        # see if the MD5 matches only if REMOTE_USER wasn't used
        curr_user_md5 = Base64.decode64(@current_user.api_key)
        if (Base64.decode64(auth_token) != curr_user_md5)
          # MD5 mismatch, bail out
          render 'shared/http_status', :locals => { :code => "403", :message => HttpStatusHelper::ERROR_CODE["message"]["403"] }, :status => 403
          return
        end
      end
      # Student's aren't allowed yet
      if @current_user.student?
        # API is available for TAs and Admins only
        render 'shared/http_status', :locals => { :code => "403", :message => HttpStatusHelper::ERROR_CODE["message"]["403"] }, :status => 403
        return
      end
    end

    #=== Description
    # Make sure that the passed format is either text, xml or json
    def check_format
      # support only plain text, xml and json
      if request.format.symbol != :text and request.format.symbol != :xml and request.format.symbol != :json
        # 406 is the default status code when the format is not support
        render :nothing => true, :status => 406
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