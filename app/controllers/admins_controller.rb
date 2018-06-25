class AdminsController < ApplicationController
  before_action :authorize_only_for_admin

  layout 'assignment_content'

  responders :flash, :collection

  def index
    respond_to do |format|
      format.html
      format.json {
        render json: Admin.select(:id, :user_name, :first_name, :last_name, :email)
      }
    end
  end

  def edit
    @user = Admin.find_by_id(params[:id])
  end

  def new
    @user = Admin.new
  end

  def update
    @user = Admin.find(params[:id])
    @user.update(user_params)
    respond_with(@user)
  end

  def create
    @user = Admin.create(user_params)
    respond_with(@user)
  end

  private

  def user_params
    params.require(:user).permit(:user_name, :first_name, :last_name, :email)
  end

  def flash_interpolation_options
    { resource_name: @user.user_name }
  end
end
