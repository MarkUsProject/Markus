class AdminsController < ApplicationController
  include UsersHelper
  before_filter  :authorize_only_for_admin

  def index
  end

  def populate
    admins_data = Admin.all(:order => 'user_name')
    # construct_table_rows defined in UsersHelper
    @admins = construct_table_rows(admins_data)
    respond_to do |format|
      format.json { render :json => @admins }
    end
  end

  def edit
    @user = Admin.find_by_id(params[:id])
  end

  def new
    @user = Admin.new(params[:user])
  end

  def update
    @user = Admin.find(params[:id])
    attrs = params[:user]
    # update_attributes supplied by ActiveRecords
    if @user.update_attributes(attrs).nil?
      flash[:error] = I18n.t('admins.update.error')
      render :edit
    else
      flash[:success] = I18n.t('admins.update.success',
        :user_name => @user.user_name)
      redirect_to :action => 'index'
    end
  end

  # Create a new Admin
  def create
    # Default attributes: role = TA or role = STUDENT
    # params[:user] is a hash of values passed to the controller
    # by the HTML form with the help of ActiveView::Helper::
    @user = Admin.new(params[:user])
    # Return unless the save is successful; save inherted from
    # active records--creates a new record if the model is new, otherwise
    # updates the existing record
    if @user.save
      flash[:success] = I18n.t('admins.create.success',
        :user_name => @user.user_name)

      redirect_to :action => 'index'
    else
      flash[:error] = I18n.t('admins.create.error')
      render 'new'
    end
  end
end
