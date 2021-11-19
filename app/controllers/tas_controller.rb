class TasController < ApplicationController
  before_action { authorize! }

  layout 'assignment_content'

  responders :flash, :collection

  def index
    respond_to do |format|
      format.html
      format.json {
        render json: current_course.tas.joins(:human).pluck_to_hash(:id, :user_name, :first_name, :last_name, :email)
      }
    end
  end

  def new
    @role = current_course.tas.new
    @role.build_grader_permission
  end

  def create
    human = Human.find_by_user_name(params[:user_name])
    @role = current_course.tas.create(human: human, **permission_params)
    respond_with @role, location: course_tas_path(current_course)
  end

  def download
    keys = [:user_name, :last_name, :first_name, :email]
    tas = current_course.tas.joins(:human).pluck_to_hash(*keys)
    case params[:format]
    when 'csv'
      output = MarkusCsv.generate(tas) { |ta| ta.values }
      format = 'text/csv'
    else
      output = tas.to_yaml
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
        @current_job = UploadRolesJob.perform_later(Ta, current_course, params[:upload_file].read, params[:encoding])
        session[:job_id] = @current_job.job_id
      end
    end
    redirect_to action: 'index'
  end

  private

  def permission_params
    params.permit(grader_permission_attributes: [:manage_assessments, :manage_submissions, :run_tests])
  end

  def flash_interpolation_options
    { resource_name: @role.human&.user_name.blank? ? @role.model_name.human : @role.user_name,
      errors: @role.errors.full_messages.join('; ')}
  end
end
