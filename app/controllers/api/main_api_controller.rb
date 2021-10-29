# Scripting API handlers for MarkUs
module Api

  # This is the parent class of all API controllers. Shared functionality of
  # all API controllers should go here.
  class MainApiController < ActionController::Base
    include ActionPolicy::Controller, SessionHandler

    before_action :check_format, :check_course, :authenticate
    skip_before_action :verify_authenticity_token

    authorize :user, through: :current_user
    authorize :role, through: :current_role
    verify_authorized
    rescue_from ActionPolicy::Unauthorized, with: :user_not_authorized
    before_action { authorize! }

    AUTHTYPE = 'MarkUsAuth'.freeze

    def page_not_found
      render 'shared/http_status',
             locals: { code: '404', message: HttpStatusHelper::ERROR_CODE['message']['404'] },
             status: 404,
             formats: request.format.symbol
    end

    private
    # Auth handler for the MarkUs API. It uses the Authorization HTTP header to
    # determine the user who issued the request. With the Authorization
    # HTTP header comes a Base 64 encoded MD5 digest of the user's private key.
    # Note that remote authentication is not supported. API key must be used.
    def authenticate
      @current_user = User.find_by_api_key(parse_auth_token(request.headers['HTTP_AUTHORIZATION']))
      user_not_authorized if @current_user.nil?
    end

    # Make sure that the passed format is either xml or json
    # If no format is provided, default to XML
    def check_format
      # This allows us to support content negotiation
      if request.headers['HTTP_ACCEPT'].nil? || request.format == '*/*'
        request.format = 'xml'
      end

      request_format = request.format.symbol
      if request_format != :xml && request_format != :json
        # 406 is the default status code when the format is not support
        head :not_acceptable
      end
    end

    def check_course
      page_not_found if current_course.nil?
    end

    # Helper method for parsing the authentication token
    def parse_auth_token(token)
      return nil if token.nil?
      if token =~ /#{AUTHTYPE} ([^\s,]+)/
        $1 # return matched part
      else
        nil
      end
    end

    # Helper method for filtering
    # Ignores default_scope order, always order by id to be consistent
    #
    # Renders an error message and returns false if the filters are malformed
    def get_collection(collection)
      filter_params = params[:filter] ? params[:filter].permit(self.class::DEFAULT_FIELDS) : {}
      if !params[:filter].nil? && !params[:filter].empty? && filter_params.empty?
        render 'shared/http_status', locals: { code: '422', message:
          'Invalid or malformed parameter values' }, status: 422
        false
      else
        collection.order('id').where(filter_params)
      end
    end

    # Checks that the symbols provided in the array aren't blank in the params
    def has_missing_params?(required_params)
      required_params.each do |param|
        return true if params[param].blank?
      end
      false
    end

    def user_not_authorized
      render 'shared/http_status',
             locals: { code: '403', message: HttpStatusHelper::ERROR_CODE['message']['403'] },
             status: 403,
             formats: request.format.symbol
    end

    protected

    def implicit_authorization_target
      OpenStruct.new policy_class: MainApiPolicy
    end
  end
end # end Api module
