module Api
  # API controller for Roles
  class RolesController < MainApiController
    # Define default fields to display for index and show methods
    END_USER_FIELDS = [:user_name, :email, :id_number, :first_name, :last_name].freeze
    ROLE_FIELDS = [:type, :grace_credits, :hidden].freeze
    DEFAULT_FIELDS = [:id, *END_USER_FIELDS, *ROLE_FIELDS].freeze

    # Returns users and their attributes
    # Optional: filter, fields
    def index
      roles = filtered_roles || return
      respond_to do |format|
        format.xml do
          render xml: roles.to_xml(methods: DEFAULT_FIELDS,
                                   only: DEFAULT_FIELDS,
                                   root: :roles,
                                   skip_types: true)
        end
        format.json { render json: roles.to_json(only: DEFAULT_FIELDS, methods: DEFAULT_FIELDS) }
      end
    end

    # Creates a new role and user if it does not exist
    # Requires: user_name, type, first_name, last_name
    # Optional: section_name, grace_credits
    def create
      create_role
    end

    # Returns a user and its attributes
    # Requires: id
    # Optional: filter, fields
    def show
      role = Role.find_by_id(params[:id])
      if role.nil?
        # No user with that id
        render 'shared/http_status', locals: { code: '404', message: 'No user exists with that id' }, status: 404
      else
        respond_to do |format|
          format.xml do
            render xml: role.to_xml(methods: DEFAULT_FIELDS,
                                    only: DEFAULT_FIELDS,
                                    root: :role,
                                    skip_types: true)
          end
          format.json { render json: role.to_json(only: DEFAULT_FIELDS, methods: DEFAULT_FIELDS) }
        end
      end
    end

    # Requires: id
    # Optional: first_name, last_name, user_name, section_name, grace_credits
    def update
      role = Role.find_by_id(params[:id])
      if role.nil?
        render 'shared/http_status', locals: { code: '404', message: 'User was not found' }, status: 404
      else
        update_role(role)
      end
    end

    # Update a user's attributes based on their user_name as opposed
    # to their id (use the regular update method instead)
    # Requires: user_name
    def update_by_username
      role = find_role_by_username
      update_role(role) unless role.nil?
    end

    # Creates a new user or unhides a user if they already exist
    # Requires: user_name, type, first_name, last_name
    # Optional: section_name, grace_credits
    def create_or_unhide
      role = find_role_by_username
      if role.nil?
        create_role
      else
        role.update!(hidden: false)
        render 'shared/http_status', locals: { code: '200', message:
            HttpStatusHelper::ERROR_CODE['message']['200'] }, status: 200
      end
    end

    private

    def create_role
      ApplicationRecord.transaction do
        end_user = EndUser.find_by(user_name: params[:user_name])
        role = Role.new(**role_params, end_user: end_user, course: @current_course)
        role.section = @current_course.sections.find_by(name: params[:section_name]) if params[:section_name]
        role.save!
        render 'shared/http_status', locals: { code: '201', message:
            HttpStatusHelper::ERROR_CODE['message']['201'] }, status: 201
      end
    rescue ActiveRecord::SubclassNotFound, ActiveRecord::RecordInvalid => e
      render 'shared/http_status', locals: { code: '422', message: e.to_s }, status: 422
    rescue StandardError
      render 'shared/http_status', locals: { code: '500', message:
          HttpStatusHelper::ERROR_CODE['message']['500'] }, status: 500
    end

    def update_role(role)
      ApplicationRecord.transaction do
        role.section = @current_course.sections.find_by(name: params[:section_name]) if params[:section_name]
        role.grace_credits = params[:grace_credits] if params[:grace_credits]
        role.save!
      end
      render 'shared/http_status', locals: { code: '200', message:
          HttpStatusHelper::ERROR_CODE['message']['200'] }, status: 200
    rescue ActiveRecord::SubclassNotFound, ActiveRecord::RecordInvalid => e
      render 'shared/http_status', locals: { code: '422', message: e.to_s }, status: 422
    rescue StandardError
      render 'shared/http_status', locals: { code: '500', message:
          HttpStatusHelper::ERROR_CODE['message']['500'] }, status: 500
    end

    def find_role_by_username
      if has_missing_params?([:user_name])
        # incomplete/invalid HTTP params
        render 'shared/http_status', locals: { code: '422', message:
            HttpStatusHelper::ERROR_CODE['message']['422'] }, status: 422
        return
      end

      # Check if that user_name is taken
      end_user = EndUser.find_by_user_name(params[:user_name])
      role = Role.find_by(end_user: end_user, course: @current_course)
      if role.nil?
        render 'shared/http_status', locals: { code: '404', message: 'Role was not found' }, status: 404
        return
      end
      role
    end

    def filtered_roles
      collection = Role.includes(:end_user).where(params.permit(:course_id)).order(:id)
      if params[:filter]&.present?
        role_filter = params[:filter].permit(*ROLE_FIELDS).to_h
        end_user_filter = params[:filter].permit(*END_USER_FIELDS).to_h.map { |k, v| ["users.#{k}", v] }.to_h
        filter_params = { **role_filter, **end_user_filter }
        if filter_params.empty?
          render 'shared/http_status',
                 locals: { code: '422', message: 'Invalid or malformed parameter values' }, status: 422
          return false
        else
          return collection.where(filter_params)
        end
      end
      collection
    end

    def role_params
      params.permit(:type, :grace_credits)
    end
  end
end
