module Api
  # Allows for adding, modifying and showing Markus users.
  # Uses Rails' RESTful routes (check 'rake routes' for the configured routes)
  class UsersController < MainApiController
    # Define default fields to display for index and show methods
    DEFAULT_FIELDS = [:id, :user_name, :email, :id_number, :type, :first_name, :last_name].freeze

    # Returns users and their attributes
    # Optional: filter, fields
    def index
      users = get_collection(visible_users) || return

      respond_to do |format|
        format.xml { render xml: users.to_xml(only: DEFAULT_FIELDS, root: :users, skip_types: true) }
        format.json { render json: users.to_json(only: DEFAULT_FIELDS) }
      end
    end

    # Creates a new user
    # Requires: user_name, type, first_name, last_name
    # Optional: section_name, grace_credits
    def create
      if has_missing_params?([:user_name, :type, :first_name, :last_name])
        # incomplete/invalid HTTP params
        render 'shared/http_status', locals: { code: '422', message:
          HttpStatusHelper::ERROR_CODE['message']['422'] }, status: :unprocessable_content
        return
      end

      # Check if that user_name is taken
      user = User.find_by(user_name: params[:user_name])
      unless user.nil?
        render 'shared/http_status', locals: { code: '409', message:
          'User already exists' }, status: :conflict
        return
      end

      # No conflict found, so create new user
      param_user_type = params[:type].camelize.downcase
      params.delete(:type)

      begin
        case param_user_type
        when 'enduser'
          EndUser.create!(params.permit(*DEFAULT_FIELDS))
        when 'adminuser'
          AdminUser.create!(params.permit(*DEFAULT_FIELDS))
        else
          render 'shared/http_status', locals: { code: '422', message: 'Unknown user type' },
                                       status: :unprocessable_content
          return
        end
      rescue ActiveRecord::SubclassNotFound, ActiveRecord::RecordInvalid => e
        render 'shared/http_status', locals: { code: '422', message: e.to_s }, status: :unprocessable_content
      else
        render 'shared/http_status',
               locals: { code: '201', message: HttpStatusHelper::ERROR_CODE['message']['201'] }, status: :created
      end
    end

    # Returns a user and its attributes
    # Requires: id
    # Optional: filter, fields
    def show
      user = visible_users.find_by(id: params[:id])
      if user.nil?
        # No user with that id
        render 'shared/http_status', locals: { code: '404', message:
          'No user exists with that id' }, status: :not_found
      else
        respond_to do |format|
          format.xml { render xml: user.to_xml(only: DEFAULT_FIELDS, root: :user, skip_types: true) }
          format.json { render json: user.to_json(only: DEFAULT_FIELDS) }
        end
      end
    end

    # Requires: id
    # Optional: first_name, last_name, user_name
    def update
      user = visible_users.find_by(id: params[:id])
      if user.nil?
        render 'shared/http_status', locals: { code: '404', message: 'User was not found' }, status: :not_found
        return
      end
      user.update!(user_params)
    rescue ActiveRecord::SubclassNotFound, ActiveRecord::RecordInvalid => e
      render 'shared/http_status', locals: { code: '422', message: e.to_s }, status: :unprocessable_content
    rescue StandardError
      render 'shared/http_status', locals: { code: '500', message:
        HttpStatusHelper::ERROR_CODE['message']['500'] }, status: :internal_server_error
    else
      render 'shared/http_status', locals: { code: '200', message:
        HttpStatusHelper::ERROR_CODE['message']['200'] }, status: :ok
    end

    # Update a user's attributes based on their user_name as opposed
    # to their id (use the regular update method instead)
    # Requires: user_name
    def update_by_username
      if has_missing_params?([:user_name])
        # incomplete/invalid HTTP params
        render 'shared/http_status',
               locals: { code: '422', message: HttpStatusHelper::ERROR_CODE['message']['422'] },
               status: :unprocessable_content
        return
      end

      user = User.find_by(user_name: params[:user_name])
      if user.nil?
        render 'shared/http_status', locals: { code: '404', message: 'User was not found' }, status: :not_found
        return
      end
      user.update!(user_params)
    rescue ActiveRecord::SubclassNotFound, ActiveRecord::RecordInvalid => e
      render 'shared/http_status', locals: { code: '422', message: e.to_s }, status: :unprocessable_content
    rescue StandardError
      render 'shared/http_status', locals: { code: '500', message:
        HttpStatusHelper::ERROR_CODE['message']['500'] }, status: :internal_server_error
    else
      render 'shared/http_status', locals: { code: '200', message:
        HttpStatusHelper::ERROR_CODE['message']['200'] }, status: :ok
    end

    private

    # Do not make AutotestUser users visible
    def visible_users
      User.where.not(type: :AutotestUser)
    end

    def user_params
      params.permit(:user_name, :email, :id_number, :first_name, :last_name)
    end
  end
end
