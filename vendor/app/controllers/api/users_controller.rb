module Api

  #=== Description
  # Allows for adding, modifying and showing users into MarkUs.
  # Uses Rails' RESTful routes (check 'rake routes' for the configured routes)
  class UsersController < MainApiController
    # Requires user_name, user_type,  last_name, first_name, [section_name], [grace_credits]
    def create
      if has_missing_params?(params)
        # incomplete/invalid HTTP params
        render 'shared/http_status', :locals => { :code => "422", :message => HttpStatusHelper::ERROR_CODE["message"]["422"] }, :status => 422
        return
      end

      # check if there is an existing user
      user = User.find_by_user_name(params[:user_name])
      if !user.nil?
        render 'shared/http_status', :locals => { :code => "409", :message => "User already exists" }, :status => 409
        return
      end

      # No user found so create new one
      param_user_type = params[:user_type].downcase
      if param_user_type == "student"
        user_type = Student
      elsif param_user_type == "ta" || param_user_type == "grader"
        user_type = Ta
      elsif param_user_type == "admin"
        user_type = Admin
      else # Unknown user_type, Invalid HTTP params.
        render 'shared/http_status', :locals => { :code => "422", :message => "Unknown user type" }, :status => 422
        return
      end

      attributes = { :user_name => params[:user_name] }
      attributes = process_attributes(params, attributes)

      new_user = user_type.new(attributes)
      if !new_user.save
        # Some error occurred
        render 'shared/http_status', :locals => { :code => "500", :message => HttpStatusHelper::ERROR_CODE["message"]["500"] }, :status => 500
        return
      end

      # Otherwise everything went alright.
      render 'shared/http_status', :locals => { :code => "200", :message => HttpStatusHelper::ERROR_CODE["message"]["200"] }, :status => 200
    end

    # Requires nothing, does nothing
    def destroy
      # Admins should not be deleting users at all so pretend this URL does not exist
      render 'shared/http_status', :locals => { :code => "404", :message => HttpStatusHelper::ERROR_CODE["message"]["404"] }, :status => 404
    end

    # Requires user_name, [first_name], [last_name], [new_user_name], [section_name], [grace_credits]
    def update
      if params[:user_name].blank?
        # incomplete/invalid HTTP params
        render 'shared/http_status', :locals => { :code => "422", :message => HttpStatusHelper::ERROR_CODE["message"]["422"] }, :status => 422
        return
      end

      # If no user is found, render an error.
      user = User.find_by_user_name(params[:user_name])
      if user.nil?
        render 'shared/http_status', :locals => { :code => "404", :message => "User was not found" }, :status => 404
        return
      end

      updated_user_name = params[:user_name]
      if !params[:new_user_name].blank?
        # Make sure new user_name does not exist
        if !User.find_by_user_name(params[:new_user_name]).nil?
          render 'shared/http_status', :locals => { :code => "409", :message => "User already exists" }, :status => 409
          return
        end
        updated_user_name = params[:new_user_name]
      end

      attributes={:user_name => updated_user_name}
      attributes = process_attributes(params, attributes)

      user.attributes = attributes
      if !user.save
        # Some error occurred
        render 'shared/http_status', :locals => { :code => "500", :message => HttpStatusHelper::ERROR_CODE["message"]["500"] }, :status => 500
        return
      end

      # Otherwise everything went alright.
      render 'shared/http_status', :locals => { :code => "200", :message => HttpStatusHelper::ERROR_CODE["message"]["200"] }, :status => 200
      return
    end

    # Requires nothing
    def index
      users = User.all

      respond_to do |format|
        format.any{render :text => get_plain_text_for_users(users)}
        format.json{render :json => users.to_json(:only => [ :user_name, :type, :first_name, :last_name ])}
        format.xml{render :xml => users.to_xml(:only => [ :user_name, :type, :first_name, :last_name ])}
      end
    end

    # Requires user_name
    def show
      if params[:user_name].blank?
        # incomplete/invalid HTTP params
        render 'shared/http_status', :locals => { :code => "422", :message => "Missing user name" }, :status => 422
        return
      end

      # check if there's a valid user.
      user = User.find_by_user_name(params[:user_name])
      if user.nil?
        # no such user
        render 'shared/http_status', :locals => { :code => "404", :message => "User was not found" }, :status => 404
        return
      end

      # Everything went fine, send the response according to the user's format.
      respond_to do |format|
        format.any{render :text => get_plain_text_for_users([user])}
        format.json{render :json => user.to_json(:only => [ :user_name, :type, :first_name, :last_name ])}
        format.xml{render :xml => user.to_xml(:only => [ :user_name, :type, :first_name, :last_name ])}
      end
    end

    private
    
    # Get the plain text representation for users
    def get_plain_text_for_users(users)
      data=""
      
      users.each do |user| 
        data += t('user.user_name') + ": " + user.user_name + "\n" +
                              t('user.user_type') + ": " + user.type + "\n" +
                              t('user.first_name') + ": " + user.first_name + "\n" +
                              t('user.last_name') + ": " + user.last_name + "\n\n" 
      end
      
      return data
    end
    
    # Process the parameters passed
    def process_attributes(params, attributes)
        # allow the user to provide the section name instead of an id which is meaningless
        # thus we have to retrieve the id here
        if !params[:section_name].blank?
           section = Section.find_by_name(params[:section_name])
           if !section.blank?
            attributes["section_id"] = section.id
           end
        end

        if !params[:last_name].blank?
          attributes["last_name"] =  params[:last_name]
        end
        if !params[:first_name].blank?
          attributes["first_name"] = params[:first_name]
        end
        if !params[:grace_credits].blank?
          attributes["grace_credits"] = params[:grace_credits]
        end
        if !params[:user_type].blank?
          attributes["type"] = params[:user_type]
        end

        return attributes
    end

    # Checks user_name, first_name, last_name, user_type.
    def has_missing_params?(params)
      return params[:user_name].blank? || params[:user_type].blank? ||
         params[:first_name].blank? || params[:last_name].blank?
    end
  end # end UsersController
end