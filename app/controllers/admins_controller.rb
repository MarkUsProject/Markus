class AdminsController < ApplicationController
  include AdminsHelper
  before_filter  :authorize_only_for_admin

  layout 'assignment_content'

  def index
  end

  def populate
    render json: get_admins_table_info
  end

  def edit
    @user = Admin.find_by_id(params[:id])
  end

  def new
    @user = Admin.new
  end

  def update
    @user = Admin.find(params[:id])
    # update_attributes supplied by ActiveRecords
    if @user.update_attributes(user_params).nil?
      flash_message(:error, I18n.t('admins.update.error'))
      render :edit
    else
      flash_message(:success, I18n.t('admins.update.success',
                                     user_name: @user.user_name))
      redirect_to action: 'index'
    end
  end

  # Create a new Admin
  def create
    # Default attributes: role = TA or role = STUDENT
    # params[:user] is a hash of values passed to the controller
    # by the HTML form with the help of ActiveView::Helper::
    @user = Admin.new(user_params)
    # Return unless the save is successful; save inherted from
    # active records--creates a new record if the model is new, otherwise
    # updates the existing record
    if @user.save
      flash_message(:success, I18n.t('admins.create.success',
                                     user_name: @user.user_name))
      redirect_to action: 'index'
    else
      flash_message(:error, I18n.t('admins.create.error'))
      render 'new'
    end
  end

  private

  def user_params
    params.require(:user).permit(:user_name, :first_name, :last_name)
  end
end
