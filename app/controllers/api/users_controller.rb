module Api

  #=== Description
  # Allows for pushing of test results into MarkUs (e.g. from automated test runs).
  # Uses Rails' RESTful routes (check 'rake routes' for the configured routes)
  class UsersController < MainApiController
    def create
      if !request.post?
        # pretend this URL does not exist
        render :file => "#{RAILS_ROOT}/public/404.html", :status => 404
        return
      end
      if !has_required_http_params?(params)
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
      row = [params[:user_name], params[:last_name], params[:first_name]]

      user_class = Student
      if params[:user_class] == "Ta"
        user_class = Ta
      elsif params[:user_class] == "Admin"
        user_class = Admin
      end

      if(User.add_user(user_class, row))
          render :file => "#{RAILS_ROOT}/public/200.xml", :status => 200
          return
      end

      # Some other error occurred
      render :file => "#{RAILS_ROOT}/public/500.xml", :status => 500
      return
    end


    def show
      if !request.get?
        # pretend this URL does not exist
        render :file => "#{RAILS_ROOT}/public/404.html", :status => 404
        return
      end
      if !has_required_http_params?(params)
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
      details = "Username: " + user.user_name + " First: " + user.first_name + " Last: " + user.last_name
      send_data details, :disposition => 'inline', :filename => user.user_name
    end

    private

    # Helper method to check for required HTTP parameters
    def has_required_http_params?(param_hash)
      # Note: The blank? method is a Rails extension.
      # Specific keys have to be present, and their values
      # must not be blank.
      return !param_hash[:user_name].blank? &&
        !param_hash[:first_name].blank? &&
        !param_hash[:last_name].blank? &&
        !param_hash[:user_class].blank?
    end
  end # end TestResultsController
end