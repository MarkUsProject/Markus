module Api

  #=== Description
  # Allows for adding, modifying and showing users into MarkUs.
  # Uses Rails' RESTful routes (check 'rake routes' for the configured routes)
  class UsersController < MainApiController
    # Requires nothing
    def index
      users = get_collection(User)
      default_fields = [:id, :user_name, :type, :first_name, :last_name,
                        :grace_credits, :notes_count];
      fields = fields_to_render(default_fields)

      respond_to do |format|
        format.any{render :text => get_plain_text('user', users, fields)}
        format.json{render :json => users.to_json(:only => fields)}
        format.xml{render :xml => users.to_xml(:only => fields, :root => 'users',
          :skip_types => 'true')}
      end
    end

    # Requires user_name, type, last_name, first_name, [section_name], [grace_credits]
    def create
      if has_missing_params?(params)
        # incomplete/invalid HTTP params
        render 'shared/http_status', :locals => {:code => '422', :message =>
          HttpStatusHelper::ERROR_CODE['message']['422']}, :status => 422
        return
      end

      # check if there is an existing user
      user = User.find_by_user_name(params[:user_name])
      if !user.nil?
        render 'shared/http_status', :locals => {:code => '409', :message =>
          'User already exists'}, :status => 409
        return
      end

      # No user found so create new one
      param_user_type = params[:type].downcase
      if param_user_type == "student"
        user_type = Student
      elsif param_user_type == "ta" || param_user_type == "grader"
        user_type = Ta
      elsif param_user_type == "admin"
        user_type = Admin
      else # Unknown user_type, Invalid HTTP params.
        render 'shared/http_status', :locals => { :code => '422', :message =>
          'Unknown user type' }, :status => 422
        return
      end

      attributes = { :user_name => params[:user_name] }
      attributes = process_attributes(params, attributes)

      new_user = user_type.new(attributes)
      if !new_user.save
        # Some error occurred
        render 'shared/http_status', :locals => {:code => '500', :message =>
          HttpStatusHelper::ERROR_CODE['message']['500']}, :status => 500
        return
      end

      # Otherwise everything went alright.
      render 'shared/http_status', :locals => {:code => '201', :message =>
        HttpStatusHelper::ERROR_CODE['message']['201']}, :status => 201
    end

    # Requires user_name
    def show
      # Check if it's a numeric string
      if !!(params[:id] =~ /^[0-9]+$/)
        user = User.find_by_id(params[:id])
        if user.nil?
          # No user with that id
          render 'shared/http_status', :locals => {:code => '404', :message =>
            'No user exists with that id'}, :status => 404
          return
        else
          default_fields = [:id, :user_name, :type, :first_name, :last_name,
                            :grace_credits, :notes_count];
          fields = fields_to_render(default_fields)

          respond_to do |format|
            format.any{render :text => get_plain_text('user', user, fields)}
            format.json{render :json => user.to_json(:only => fields)}
            format.xml{render :xml => user.to_xml(:only => fields, :root => 'users',
              :skip_types => 'true')}
          end
        end
      else
        # Invalid params if it wasn't a numeric string
        render 'shared/http_status', :locals => {:code => '422', :message =>
          'Invalid id'}, :status => 422
        return
      end
    end

    # Requires nothing, does nothing
    def destroy
      # Admins should not be deleting users at all so pretend this URL does not exist
      render 'shared/http_status', :locals => {:code => '404', :message =>
        HttpStatusHelper::ERROR_CODE['message']['404'] }, :status => 404
    end

    # Requires [first_name], [last_name], [user_name], [section_name], [grace_credits]
    def update
      # If no user is found, render an error.
      user = User.find_by_id(params[:id])
      if user.nil?
        render 'shared/http_status', :locals => {:code => '404', :message =>
          'User was not found'}, :status => 404
        return
      end

      if !params[:user_name].blank?
        # Make sure another user isn't using it
        other_user = User.find_by_user_name(params[:user_name])
        if !other_user.nil? && other_user != user
          render 'shared/http_status', :locals => {:code => '409', :message =>
            'Username already in use'}, :status => 409
          return
        end
        updated_user_name = params[:user_name]
      end

      attributes = {:user_name => updated_user_name}
      attributes = process_attributes(params, attributes)

      user.attributes = attributes
      if !user.save
        # Some error occurred
        render 'shared/http_status', :locals => { :code => '500', :message =>
          HttpStatusHelper::ERROR_CODE['message']['500'] }, :status => 500
        return
      end

      # Otherwise everything went alright.
      render 'shared/http_status', :locals => {:code => '200', :message =>
        HttpStatusHelper::ERROR_CODE['message']['200']}, :status => 200
      return
    end

    # Process the parameters passed for user creation and update
    def process_attributes(params, attributes)
        # Get the id of the section corresponding to :section_name
        if !params[:section_name].blank?
           section = Section.find_by_name(params[:section_name])
           if !section.blank?
            attributes["section_id"] = section.id
           end
        end

        parameters = ["last_name", "first_name", "type", "grace_credits"]
        parameters.each do |parameter|
          key = parameter.to_sym
          if !params[key].blank?
            attributes[parameter] = params[key]
          end
        end

        return attributes
    end

    # Checks user_name, first_name, last_name, type
    def has_missing_params?(params)
      return params[:user_name].blank? || params[:type].blank? ||
         params[:first_name].blank? || params[:last_name].blank?
    end
  end # end UsersController
end
