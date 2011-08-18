class AdminsController < ApplicationController
  include UsersHelper
  before_filter  :authorize_only_for_admin

  def index
  end

  def populate
    admins_data = Admin.find(:all, :order => "user_name")
    # construct_table_rows defined in UsersHelper
    @admins = construct_table_rows(admins_data)
  end

  def edit
    @user = Admin.find_by_id(params[:id])
  end

  def new
  end

  def update
    @user = Admin.find(params[:id])
    attrs = params[:user]
    # update_attributes supplied by ActiveRecords
    if !@user.update_attributes(attrs)
      render :action => :edit
    else
      flash[:edit_notice] = I18n.t("admins.success",
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
    return unless @user.save

    redirect_to :action => 'index'
  end
end
