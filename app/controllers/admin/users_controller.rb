module Admin
  class UsersController < ApplicationController
    DEFAULT_FIELDS = [:id, :user_name, :email, :id_number, :type, :first_name, :last_name].freeze
    before_action { authorize! }

    respond_to :html
    layout 'assignment_content'

    def index
      respond_to do |format|
        format.html
        format.json { render json: visible_users.order(:created_at).to_json(only: DEFAULT_FIELDS) }
      end
    end

    def new
      @user = User.new
    end

    def create
      user_params = params.require(:user)
      user_type = user_params[:type].camelize.downcase
      case user_type
      when 'enduser'
        @user = EndUser.create(user_params.permit(:user_name, :email, :id_number, :first_name, :last_name))
      when 'adminuser'
        @user = AdminUser.create(user_params.permit(:user_name, :email, :id_number, :first_name, :last_name))
      end
      respond_with @user,
                   location: -> { admin_users_path },
                   action: -> { new_admin_course_path }
    end

    def edit
      @user = record
    end

    def update
      @user = record
      user_params = params.require(@user.model_name.to_s.underscore)
      @user.update(user_params.permit(:user_name, :email, :id_number, :first_name, :last_name))
      respond_with @user, location: -> { edit_admin_user_path(@user) }
    end

    protected

    def implicit_authorization_target
      OpenStruct.new policy_class: Admin::UserPolicy
    end

    private

    # Do not make AutotestUser users visible
    def visible_users
      User.where.not(type: :AutotestUser)
    end

    def flash_interpolation_options
      { resource_name: @user.user_name.presence || @user.model_name.human,
        errors: @user.errors.full_messages.join('; ') }
    end
  end
end
