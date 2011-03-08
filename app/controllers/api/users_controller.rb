module Api

  #=== Description
  # Allows for pushing of test results into MarkUs (e.g. from automated test runs).
  # Uses Rails' RESTful routes (check 'rake routes' for the configured routes)
  class UsersController < MainApiController
    # Requires user_name, last_name, first_name, user_type
    def create
      if !request.post?
        # pretend this URL does not exist
        render :file => "#{RAILS_ROOT}/public/404.html", :status => 404
        return
      end

      if !has_required_http_params_and_user_type?(params)
        # incomplete/invalid HTTP params
        render :file => "#{RAILS_ROOT}/public/422.xml", :status => 422
        return
      end

      # check if there is an existing user
      user = User.find_by_user_name(params[:user_name])
      if !user.nil?
        render :file => "#{RAILS_ROOT}/public/409.xml", :status => 409
        return
      end

      # No user found so create new one

      if params[:user_type].downcase == "student"
        user_type = Student
      elsif params[:user_type].downcase == "ta" || params[:user_type].downcase == "grader"
        user_type = Ta
      elsif params[:user_type].downcase == "admin"
        user_type = Admin
      else # Unkown user_type, Invalid HTTP params.
        render :file => "#{RAILS_ROOT}/public/422.xml", :status => 409
        return
      end

      attributes = {:user_name => params[:user_name],
                    :last_name => params[:last_name],
                    :first_name => params[:first_name]}

      new_user = user_type.new(attributes)
      if !new_user.save
        # Some error occurred
        render :file => "#{RAILS_ROOT}/public/500.xml", :status => 500
        return
      end

      # Otherwise everything went alright.
      render :file => "#{RAILS_ROOT}/public/200.xml", :status => 200
      return
    end

    # Requires nothing, does nothing.
    def destroy
      # Admins should not be deleting users at all so pretend this URL does not exist
      render :file => "#{RAILS_ROOT}/public/404.html", :status => 404
      return
    end

    # Requires user_name, first_name, last_name [, new_user_name]
    def update
      if !request.put?
        # pretend this URL does not exist
        render :file => "#{RAILS_ROOT}/public/404.html", :status => 404
        return
      end

      if !has_required_http_params?(params)
        # incomplete/invalid HTTP params
        render :file => "#{RAILS_ROOT}/public/422.xml", :status => 422
        return
      end

      # If no user is found, render an error.
      # SEE: render will change to a view with a more meaningful message.
      user = User.find_by_user_name(params[:user_name])
      if user.nil?
        render :file => "#{RAILS_ROOT}/public/422.xml", :status => 409
        return
      end

      updated_user_name = params[:user_name]
      if !params[:new_user_name].blank?
        updated_user_name = params[:new_user_name]
      end

      attributes = {:user_name => updated_user_name,
                    :last_name => params[:last_name],
                    :first_name => params[:first_name]}

      user.attributes = attributes
      if !user.save
        # Some error occurred
        render :file => "#{RAILS_ROOT}/public/500.xml", :status => 500
        return
      end

      # Otherwise everything went alright.
      render :file => "#{RAILS_ROOT}/public/200.xml", :status => 200
      return
    end

    # Requires user_name
    def show
      if !request.get?
        # pretend this URL does not exist
        render :file => "#{RAILS_ROOT}/public/404.html", :status => 404
        return
      end

      if !has_required_http_param_user_name?(params)
        # incomplete/invalid HTTP params
        render :file => "#{RAILS_ROOT}/public/422.xml", :status => 422
        return
      end
      # check if there's a valid submission
      user = User.find_by_user_name(params[:user_name])

      if user.nil?
        # no such user
        render :file => "#{RAILS_ROOT}/public/422.xml", :status => 422
        return
      end

      # Everything went fine; send file_content
      details = "\nUsername: " + user.user_name +
          "\nType: " + user.type +
          "\nFirst Name: " + user.first_name +
          "\nLast Name: " + user.last_name
      send_data details, :disposition => 'inline', :filename => user.user_name
    end

    private

    # Helper method to check for required HTTP parameters
    def has_required_http_param_user_name?(param_hash)
      # Note: The blank? method is a Rails extension.
      # Specific keys have to be present, and their values
      # must not be blank.
      return !param_hash[:user_name].blank?
    end

    def has_required_http_params?(param_hash)
      return has_required_http_param_user_name?(param_hash) &&
          !param_hash[:first_name].blank? &&
          !param_hash[:last_name].blank? &&
    end

    def has_required_http_params_and_user_type?(param_hash)
      return has_required_http_params &&
          !param_hash[:user_type].blank?
  end # end TestResultsController
end