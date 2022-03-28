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

    def edit
      @user = visible_users.find_by(id: params[:id])
    end

    def update
      @user = visible_users.find_by(id: params[:id])
      if @user.admin_user?
        @user.update(admin_user_params)
      else
        @user.update(end_user_params)
      end
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

    def end_user_params
      params.require(:end_user).permit(:user_name, :email, :id_number, :first_name, :last_name)
    end

    def admin_user_params
      params.require(:admin_user).permit(:user_name, :email, :id_number, :first_name, :last_name)
    end

    def flash_interpolation_options
      { resource_name: @user.user_name.presence || @user.model_name.human,
        errors: @user.errors.full_messages.join('; ') }
    end
  end
end
