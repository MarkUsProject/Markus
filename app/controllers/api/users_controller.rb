module Api

  # Allows for adding, modifying and showing Markus users.
  # Uses Rails' RESTful routes (check 'rake routes' for the configured routes)
  class UsersController < MainApiController
    # Define default fields to display for index and show methods
    @@default_fields = [:id, :user_name, :type, :first_name, :last_name,
                        :grace_credits, :notes_count]

    # Returns users and their attributes
    # Optional: filter, fields
    def index
      users = get_collection(User)

      fields = fields_to_render(@@default_fields)

      respond_to do |format|
        format.xml{render xml: users.to_xml(only: fields, root: 'users',
          skip_types: 'true')}
        format.json{render json: users.to_json(only: fields)}
      end
    end

    # Creates a new user
    # Requires: user_name, type, first_name, last_name
    # Optional: section_name, grace_credits
    def create
      if has_missing_params?([:user_name, :type, :first_name, :last_name])
        # incomplete/invalid HTTP params
        render 'shared/http_status', locals: {code: '422', message:
          HttpStatusHelper::ERROR_CODE['message']['422']}, status: 422
        return
      end

      # Check if that user_name is taken
      user = User.find_by_user_name(params[:user_name])
      unless user.nil?
        render 'shared/http_status', locals: {code: '409', message:
          'User already exists'}, status: 409
        return
      end

      # No conflict found, so create new user
      param_user_type = params[:type].downcase
      params.delete(:type)

      if param_user_type == 'student'
        user_class = Student
        user_type = User::STUDENT
      elsif param_user_type == 'ta' || param_user_type == 'grader'
        user_class = Ta
        user_type = User::TA
      elsif param_user_type == 'admin'
        user_class = Admin
        user_type = User::ADMIN
      elsif param_user_type == 'testserver'
        user_class = TestServer
        user_type = User::TEST_SERVER
      else # Unknown user type, Invalid HTTP params.
        render 'shared/http_status', locals: { code: '422', message:
          'Unknown user type' }, status: 422
        return
      end

      attributes = { user_name: params[:user_name] }
      attributes = process_attributes(params, attributes)

      new_user = user_class.new(attributes)
      new_user.type = user_type
      unless new_user.save
        # Some error occurred
        render 'shared/http_status', locals: {code: '500', message:
          HttpStatusHelper::ERROR_CODE['message']['500']}, status: 500
        return
      end

      # Otherwise everything went alright.
      render 'shared/http_status', locals: {code: '201', message:
        HttpStatusHelper::ERROR_CODE['message']['201']}, status: 201
    end

    # Returns a user and its attributes
    # Requires: id
    # Optional: filter, fields
    def show
      user = User.find_by_id(params[:id])
      if user.nil?
        # No user with that id
        render 'shared/http_status', locals: {code: '404', message:
          'No user exists with that id'}, status: 404
      else
        fields = fields_to_render(@@default_fields)

        respond_to do |format|
          format.xml{render xml: user.to_xml(only: fields, root: 'user',
            skip_types: 'true')}
          format.json{render json: user.to_json(only: fields)}
        end
      end
    end

    # Requires nothing, does nothing
    def destroy
      # Admins should not be deleting users, so pretend this URL doesn't exist
      render 'shared/http_status', locals: {code: '404', message:
        HttpStatusHelper::ERROR_CODE['message']['404'] }, status: 404
    end

    # Requires: id
    # Optional: first_name, last_name, user_name, section_name, grace_credits
    def update
      # If no user is found, render an error.
      user = User.find_by_id(params[:id])
      if user.nil?
        render 'shared/http_status', locals: {code: '404', message:
          'User was not found'}, status: 404
        return
      end

      # Create a hash to hold fields/values to be updated for the user
      attributes = {}

      unless params[:user_name].blank?
        # Make sure the user_name isn't taken
        other_user = User.find_by_user_name(params[:user_name])
        if !other_user.nil? && other_user != user
          render 'shared/http_status', locals: {code: '409', message:
            'Username already in use'}, status: 409
          return
        end
        attributes[:user_name] = params[:user_name]
      end

      attributes = process_attributes(params, attributes)

      user.attributes = attributes
      unless user.save
        # Some error occurred
        render 'shared/http_status', locals: { code: '500', message:
          HttpStatusHelper::ERROR_CODE['message']['500'] }, status: 500
        return
      end

      # Otherwise everything went alright.
      render 'shared/http_status', locals: {code: '200', message:
        HttpStatusHelper::ERROR_CODE['message']['200']}, status: 200
    end

    # Process the parameters passed for user creation and update
    def process_attributes(params, attributes)
      # Get the id of the section corresponding to :section_name
      unless params[:section_name].blank?
        section = Section.find_by_name(params[:section_name])
        unless section.blank?
          attributes[:section_id] = section.id
        end
      end

      parameters = [:last_name, :first_name, :type, :grace_credits]
      parameters.each do |key|
        unless params[key].blank?
          attributes[key] = params[key]
        end
      end

      attributes
    end
  end # end UsersController
end
