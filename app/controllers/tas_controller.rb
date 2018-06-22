class TasController < ApplicationController
  before_action :authorize_only_for_admin

  layout 'assignment_content'

  responders :flash, :collection

  def index
    respond_to do |format|
      format.html
      format.json {
        render json: Ta.select(:id, :user_name, :first_name, :last_name, :email)
      }
    end
  end

  def new
    @user = Ta.new
  end

  def edit
    @user = Ta.find_by_id(params[:id])
  end

  def destroy
    @user = Ta.find(params[:id])
    @user.destroy
    respond_with(@user)
  end

  def update
    @user = Ta.find(params[:user][:id])
    @user.update(user_params)
    respond_with(@user)
  end

  def create
    @user = Ta.create(user_params)
    respond_with(@user)
  end

  #downloads users with the given role as a csv list
  def download_ta_list
    #find all the users
    tas = Ta.order(:user_name)
    case params[:format]
    when 'csv'
      output = MarkusCSV.generate(tas) do |ta|
        [ta.user_name,ta.last_name,ta.first_name,ta.email]
      end
      format = 'text/csv'
    when 'xml'
      output = tas.to_xml
      format = 'text/xml'
    else
      # Raise exception?
      output = tas.to_xml
      format = 'text/xml'
    end
    send_data(output,
              type: format,
              filename: "ta_list.#{params[:format]}",
              disposition: 'attachment')
  end

  def upload_ta_list
    if params[:userlist]
      result = User.upload_user_list(Ta, params[:userlist].read, params[:encoding])
      unless result[:invalid_lines].blank?
        flash_message(:error, result[:invalid_lines])
      end
      unless result[:valid_lines].blank?
        flash_message(:success, result[:valid_lines])
      end
    else
      flash_message(:error, I18n.t('csv.invalid_csv'))
    end
    redirect_to action: 'index'
  end

  def refresh_graph
    @assignment = Assignment.find(params[:assignment])
    @current_ta = Ta.find(params[:id])
  end

  private

  def user_params
    params.require(:user).permit(:user_name, :last_name, :first_name, :email)
  end

  def flash_interpolation_options
    { resource_name: @user.user_name }
  end
end
