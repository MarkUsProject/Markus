class TasController < ApplicationController
  before_filter  :authorize_only_for_admin

  layout 'assignment_content'

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
      flash_message(:success, I18n.t('tas.update.success',
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
      User.transaction do
        user_names = Set.new
        tas = []
        result = MarkusCSV.parse(params[:userlist],
                                 skip_blanks: true,
                                 row_sep: :auto,
                                 encoding: params[:encoding]) do |row|
          row.compact! # discard unwanted nil elements
          next if row.empty?
          user_name_i = Ta::CSV_UPLOAD_ORDER.find_index(:user_name)
          raise CSVInvalidLineError if user_names.include?(row[user_name_i]) ||
                                       row.size != Ta::CSV_UPLOAD_ORDER.size
          user_names << row[user_name_i]
          tas << row
        end
        begin
          imported = Ta.import Ta::CSV_UPLOAD_ORDER, tas
          unless result[:invalid_lines].empty?
            flash_message(:error, result[:invalid_lines])
          end
          unless imported.failed_instances.empty?
            flash_message(:error, I18n.t('csv_invalid_lines') +
                                  imported.failed_instances.map { |f| f[:user_name] }.join(', '))
          end
          unless imported.ids.empty?
            Repository.get_class.__set_all_permissions
            flash_message(:success, I18n.t('csv_valid_lines', valid_line_count: imported.ids.size))
          end
        rescue ActiveRecord::RecordNotUnique => e # can trigger on uniqueness constraint validation for :user_name
          flash_message(:error, I18n.t('csv_upload_user_duplicate', user_name: e.message))
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
