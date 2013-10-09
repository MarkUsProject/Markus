class TasController < ApplicationController
  include UsersHelper
  before_filter  :authorize_only_for_admin

  def index
    @tas = Ta.all(:order => 'user_name')
  end

  def populate
    @tas_data = Ta.all(:order => 'user_name')
    # construct_table_rows defined in UsersHelper
    @tas = construct_table_rows(@tas_data)
  end

  def new
    @user = Ta.new
  end

  def edit
    @user = Ta.find_by_id(params[:id])
  end

  def update
    @user = Ta.find_by_id(params[:user][:id])
    attrs = params[:user]
    # update_attributes supplied by ActiveRecords
    if @user.update_attributes(attrs)
      flash[:success] = I18n.t('tas.update.success',
                               :user_name => @user.user_name)

      redirect_to :action => :index
    else
      flash[:error] = I18n.t('tas.update.error')
      render :edit
    end
  end

  def create
    # Default attributes: role = TA or role = STUDENT
    # params[:user] is a hash of values passed to the controller
    # by the HTML form with the help of ActiveView::Helper::
    @user = Ta.new(params[:user])
    # Return unless the save is successful; save inherted from
    # active records--creates a new record if the model is new, otherwise
    # updates the existing record
    if @user.save
      flash[:success] = I18n.t('tas.create.success',
                               :user_name => @user.user_name)
      redirect_to :action => 'index' # Redirect
    else
      flash[:error] = I18n.t('tas.create.error')
      render :new
    end
  end

  #downloads users with the given role as a csv list
  def download_ta_list
    #find all the users
    tas = Ta.all(:order => 'user_name')
    case params[:format]
    when 'csv'
      output = User.generate_csv_list(tas)
      format = 'text/csv'
    when 'xml'
      output = tas.to_xml
      format = 'text/xml'
    else
      # Raise exception?
      output = tas.to_xml
      format = 'text/xml'
    end
    send_data(output, :type => format, :disposition => 'inline')
  end

  def upload_ta_list
    if request.post? && !params[:userlist].blank?
      result = User.upload_user_list(Ta, params[:userlist], params[:encoding])
      if result == false
        flash[:notice] = I18n.t('csv.invalid_csv')
        redirect_to :action => 'index'
        return
      end
      if result[:invalid_lines].length > 0
        flash[:invalid_lines] = result[:invalid_lines]
      end
      flash[:notice] = result[:upload_notice]
    end
    redirect_to :action => 'index'
  end
end
