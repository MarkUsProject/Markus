class TasController < ApplicationController
  before_action do |_|
    authorize! with: UserPolicy
  end

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

  def download
    tas = Ta.order(:user_name)
    case params[:format]
    when 'csv'
      output = MarkusCsv.generate(tas) do |ta|
        Ta::CSV_UPLOAD_ORDER.map do |field|
          ta.send(field)
        end
      end
      format = 'text/csv'
    else
      output = []
      tas.all.each do |ta|
        output.push(user_name: ta.user_name, last_name: ta.last_name, first_name: ta.first_name, email: ta.email)
      end
      output = output.to_yaml
      format = 'text/yaml'
    end
    send_data(output,
              type: format,
              filename: "ta_list.#{params[:format]}",
              disposition: 'attachment')
  end

  def upload
    begin
      data = process_file_upload
    rescue Psych::SyntaxError => e
      flash_message(:error, t('upload_errors.syntax_error', error: e.to_s))
    rescue StandardError => e
      flash_message(:error, e.message)
    else
      if data[:type] == '.csv'
        result = User.upload_user_list(Ta, params[:upload_file].read, params[:encoding])
        flash_message(:error, result[:invalid_lines]) unless result[:invalid_lines].empty?
        flash_message(:success, result[:valid_lines]) unless result[:valid_lines].empty?
        flash_message(:error, result[:invalid_records]) unless result[:invalid_records].empty?
      end
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
    { resource_name: @user.user_name.blank? ? @user.model_name.human : @user.user_name,
      errors: @user.errors.full_messages.join('; ')}
  end
end
