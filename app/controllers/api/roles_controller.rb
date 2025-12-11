module Api
  # API controller for Roles
  class RolesController < MainApiController
    # Define default fields to display for index and show methods
    USER_FIELDS = [:user_name, :email, :id_number, :first_name, :last_name].freeze
    ROLE_FIELDS = [:type, :grace_credits, :hidden].freeze
    DEFAULT_FIELDS = [:id, *USER_FIELDS, *ROLE_FIELDS].freeze

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
      role = Role.find_by(id: params[:id])
      if role.nil?
        # No user with that id
        render 'shared/http_status', locals: { code: '404', message: 'No user exists with that id' }, status: :not_found
      elsif role.admin_role? && !@real_user.admin_user?
        render 'shared/http_status',
               locals: { code: '403', message: 'You are not allowed to view information about this user' },
               status: :forbidden
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
      role = Role.find_by(id: params[:id])
      if role.nil?
        render 'shared/http_status', locals: { code: '404', message: 'User was not found' }, status: :not_found
      elsif role.admin_role? && !@real_user.admin_user?
        render 'shared/http_status',
               locals: { code: '403', message: 'You are not allowed to update the role of this user' },
               status: :forbidden
      else
        update_role(role)
      end
    end

    # Update a user's attributes based on their user_name as opposed
    # to their id (use the regular update method instead)
    # Requires: user_name
    def update_by_username
      role = find_role_by_username
      if role.nil?
        render 'shared/http_status', locals: { code: '404', message: 'Role was not found' }, status: :not_found
        return
      elsif role.admin_role? && !@real_user.admin_user?
        render 'shared/http_status',
               locals: { code: '403', message: 'You are not allowed to update the role of this user' },
               status: :forbidden
        return
      end
      update_role(role) unless role.nil?
    end

    # Creates a new user or unhides a user if they already exist
    # Requires: user_name, type, first_name, last_name
    # Optional: section_name, grace_credits
    def create_or_unhide
      role = find_role_by_username
      if role.nil?
        create_role
      elsif role.admin_role? && !@real_user.admin_user?
        render 'shared/http_status',
               locals: { code: '403', message: 'You are not allowed to update the role of this user' },
               status: :forbidden
      else
        role.update!(hidden: false)
        render 'shared/http_status', locals: { code: '200', message:
            HttpStatusHelper::ERROR_CODE['message']['200'] }, status: :ok
      end
    end

    private

    def create_role
      unless role_params[:type] != AdminRole.name || @real_user.admin_user?
        render 'shared/http_status',
               locals: { code: '403', message: 'You are not allowed to create admin roles' },
               status: :forbidden
        return
      end
      ApplicationRecord.transaction do
        user = User.find_by(user_name: params[:user_name])
        role = Role.new(**role_params, user: user, course: @current_course)
        if params[:section_name]
          if params[:section_name].empty?
            role.section = nil
          else
            role.section = @current_course.sections.find_by!(name: params[:section_name])
          end
        end
        role.grace_credits = params[:grace_credits] if params[:grace_credits]
        role.hidden = params[:hidden].to_s.casecmp('true').zero? if params[:hidden]
        role.save!
        render 'shared/http_status', locals: { code: '201', message:
            HttpStatusHelper::ERROR_CODE['message']['201'] }, status: :created
      end
    rescue ActiveRecord::SubclassNotFound, ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound => e
      render 'shared/http_status', locals: { code: '422', message: e.to_s }, status: :unprocessable_content
    rescue StandardError
      render 'shared/http_status', locals: { code: '500', message:
          HttpStatusHelper::ERROR_CODE['message']['500'] }, status: :internal_server_error
    end

    def update_role(role)
      ApplicationRecord.transaction do
        if params[:section_name]
          if params[:section_name].empty?
            role.section = nil
          else
            role.section = @current_course.sections.find_by!(name: params[:section_name])
          end
        end
        role.grace_credits = params[:grace_credits] if params[:grace_credits]
        role.hidden = params[:hidden].to_s.casecmp('true').zero? if params[:hidden]
        role.save!
      end
      render 'shared/http_status', locals: { code: '200', message:
          HttpStatusHelper::ERROR_CODE['message']['200'] }, status: :ok
    rescue ActiveRecord::SubclassNotFound, ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound => e
      render 'shared/http_status', locals: { code: '422', message: e.to_s }, status: :unprocessable_content
    rescue StandardError
      render 'shared/http_status', locals: { code: '500', message:
          HttpStatusHelper::ERROR_CODE['message']['500'] }, status: :internal_server_error
    end

    def find_role_by_username
      if has_missing_params?([:user_name])
        # incomplete/invalid HTTP params
        render 'shared/http_status', locals: { code: '422', message:
            HttpStatusHelper::ERROR_CODE['message']['422'] }, status: :unprocessable_content
        return
      end

      # Check if that user_name is taken
      user = User.find_by(user_name: params[:user_name])
      Role.find_by(user: user, course: @current_course)
    end

    def filtered_roles
      course_id = params[:course_id]
      collection = Role.includes(:user).where(course_id: course_id).order(:id)
      collection = collection.where.not(type: AdminRole.name) unless @real_user.admin_user?
      if params[:filter].present?
        role_filter = params[:filter].permit(*ROLE_FIELDS).to_h
        user_filter = params[:filter].permit(*USER_FIELDS).to_h.transform_keys { |k| "users.#{k}" }
        filter_params = { **role_filter, **user_filter }
        if filter_params.empty?
          render 'shared/http_status',
                 locals: { code: '422', message: 'Invalid or malformed parameter values' },
                 status: :unprocessable_content
          return false
        else
          return collection.where(**filter_params)
        end
      end
      collection
    end

    def role_params
      params.permit(:type, :grace_credits, :hidden)
    end
  end
end
