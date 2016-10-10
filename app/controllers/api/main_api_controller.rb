# Scripting API handlers for MarkUs
module Api

  # This is the parent class of all API controllers. Shared functionality of
  # all API controllers should go here.
  class MainApiController < ActionController::Base

    before_filter :check_format, :authenticate

    # Unless overridden by a subclass, all routes are 404's by default
    def index
      render 'shared/http_status', locals: {code: '404', message:
        HttpStatusHelper::ERROR_CODE['message']['404']}, status: 404
    end

    def show
      render 'shared/http_status', locals: {code: '404', message:
        HttpStatusHelper::ERROR_CODE['message']['404'] }, status: 404
    end

    def create
      render 'shared/http_status', locals: {code: '404', message:
        HttpStatusHelper::ERROR_CODE['message']['404'] }, status: 404
    end

    def update
      render 'shared/http_status', locals: {code: '404', message:
        HttpStatusHelper::ERROR_CODE['message']['404'] }, status: 404
    end

    def destroy
      render 'shared/http_status', locals: {code: '404', message:
        HttpStatusHelper::ERROR_CODE['message']['404'] }, status: 404
    end

    private
    # Auth handler for the MarkUs API. It uses the Authorization HTTP header to
    # determine the user who issued the request. With the Authorization
    # HTTP header comes a Base 64 encoded MD5 digest of the user's private key.
    # Note that remote authentication is not supported. API key must be used.
    def authenticate
      auth_token = parse_auth_token(request.headers['HTTP_AUTHORIZATION'])
      # pretend resource not found if missing or authentication is invalid
      if auth_token.nil?
        render 'shared/http_status', locals: { code: '403', message:
          HttpStatusHelper::ERROR_CODE['message']['403'] }, status: 403
        return
      end

      # Find user by api_key_md5
      @current_user = User.find_by_api_key(auth_token)
      if @current_user.nil?
        # Key/username does not exist, return 403 error
        render 'shared/http_status', locals: {code: '403', message:
          HttpStatusHelper::ERROR_CODE['message']['403']}, status: 403
        return
      end

      # Student's aren't allowed yet
      if @current_user.student?
        # API is available for TAs, Admins and TestServers only
        render 'shared/http_status', locals: {code: '403', message:
          HttpStatusHelper::ERROR_CODE['message']['403']}, status: 403
      end
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
        render nothing: true, status: 406
      end
    end

    # Helper method for parsing the authentication token
    def parse_auth_token(token)
      return nil if token.nil?
      if token =~ /MarkUsAuth ([^\s,]+)/
        $1 # return matched part
      else
        nil
      end
    end

    # Helper method for filtering, limit, offset
    # Optionally accepts a collection - an object of class Active Record::Relation
    def get_collection(collection_class, collection = nil)
      # We'll append .where, .limit, and .offset to the collection
      # Ignore default_scope order, always order by id to be consistent
      if collection
        collection = collection.order('id')
      else
        collection = collection_class.order('id')
      end

      filters = {}
      # params[:filter] will match the following format:
      # param:argument,param:argument,param:argument...
      unless params[:filter].blank?
        valid_filters = /(\w+:\w+,{0,1})+/.match(params[:filter])
        unless valid_filters.nil?
          valid_filters.to_s.split(',').each do |filter|
            key, value = filter.split(':')
            if collection_class.column_names.include?(key)
              key = key.to_sym

              # Check if validation forces values to be numeric
              numericality = false
              collection_class.validators_on(key).each do |validator|
                if validator.is_a?(ActiveModel::Validations::NumericalityValidator)
                  collection = collection.where("#{key} = ?", value)
                  numericality = true
                  break
                end
              end

              # Do a case-insensitive search if dealing with strings
              unless numericality
                collection = collection.where("lower(#{key}) = ?", value.downcase)
              end
            end
          end
        end
      end

      # Apply offsets and limits, or get all if they aren't set
      collection = collection.offset(params[:offset].to_i) if !params[:offset].blank?
      collection = collection.limit(params[:limit].to_i) if !params[:limit].blank?
      collection if filters.empty?
    end

    # Helper method handling which fields to render, given the provided default
    # fields and those present in params[:fields]
    def fields_to_render(default_fields)
      fields = []
      # params[:fields] will match the following format:
      # argument,argument,argument...
      unless params[:fields].blank?
        filtered_fields = /(\w+,{0,1})+/.match(params[:fields])
        unless filtered_fields.nil?
          filtered_fields.to_s.split(',').each do |field|
            field = field.to_sym
            fields << field if default_fields.include?(field)
          end
        end
      end

      fields = default_fields if fields.empty?
      fields
    end

    # Checks that the symbols provided in the array aren't blank in the params
    def has_missing_params?(required_params)
      required_params.each do |param|
        return true if params[param].blank?
      end
      false
    end
  end
end # end Api module
