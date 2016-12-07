class TasController < ApplicationController
  include TasHelper
  before_filter  :authorize_only_for_admin

  layout 'assignment_content'

  def index
  end

  def populate
    render json: get_tas_table_info
  end

  def new
    @user = Ta.new
  end

  def edit
    @user = Ta.find_by_id(params[:id])
  end

  def destroy
    @user = Ta.find(params[:id])
    if @user && @user.destroy
      flash_message(:success, I18n.t('tas.delete.success',
                                     user_name: @user.user_name))
    else
      flash_message(:error, I18n.t('tas.delete.error'))
    end
      redirect_to action: :index
  end

  def update
    @user = Ta.find_by_id(params[:user][:id])
    # update_attributes supplied by ActiveRecords
    if @user.update_attributes(user_params)
      flash(:success, I18n.t('tas.update.success',
                             user_name: @user.user_name))
      redirect_to action: :index
    else
      flash_message(:error, I18n.t('tas.update.error'))
      render :edit
    end
  end

  def create
    # Default attributes: role = TA or role = STUDENT
    # params[:user] is a hash of values passed to the controller
    # by the HTML form with the help of ActiveView::Helper::
    @user = Ta.new(user_params)
    # Return unless the save is successful; save inherted from
    # active records--creates a new record if the model is new, otherwise
    # updates the existing record
    if @user.save
      flash_message(:success, I18n.t('tas.create.success',
                                     user_name: @user.user_name))
      redirect_to action: 'index' # Redirect
    else
      flash_message(:error, I18n.t('tas.create.error'))
      render :new
    end
  end

  #downloads users with the given role as a csv list
  def download_ta_list
    #find all the users
    tas = Ta.order(:user_name)
    case params[:format]
    when 'csv'
      output = MarkusCSV.generate(tas) do |ta|
        [ta.user_name,ta.last_name,ta.first_name]
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
      User.transaction do
        processed_users = []
        result = MarkusCSV.parse(params[:userlist],
                                 skip_blanks: true,
                                 row_sep: :auto,
                                 encoding: params[:encoding]) do |row|
          next if CSV.generate_line(row).strip.empty?
          raise CSVInvalidLineError if processed_users.include?(row[0])
          raise CSVInvalidLineError if User.add_user(Ta, row).nil?
          processed_users.push(row[0])
        end
        unless result[:invalid_lines].empty?
          flash_message(:error, result[:invalid_lines])
        end
        unless result[:valid_lines].empty?
          flash_message(:success, result[:valid_lines])
        end
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
    params.require(:user).permit(:user_name, :last_name, :first_name)
  end
end
