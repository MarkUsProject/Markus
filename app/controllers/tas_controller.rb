class TasController < ApplicationController
  before_action { authorize! }

  layout 'assignment_content'

  responders :flash, :collection

  def index
    respond_to do |format|
      format.html
      format.json do
        render json: {
          data: current_course.tas.joins(:user).pluck_to_hash(:id, :user_name, :first_name, :last_name, :email,
                                                              :hidden),
          counts: {
            all: current_course.tas.size,
            active: current_course.tas.active.size,
            inactive: current_course.tas.inactive.size
          }
        }
      end
    end
  end

  def new
    @role = current_course.tas.new
    @role.build_grader_permission
  end

  def create
    user = EndUser.find_by(user_name: end_user_params[:user_name])
    @role = current_course.tas.create(user: user, **create_update_params)
    respond_with @role, location: course_tas_path(current_course)
  end

  def edit
    @role = record
  end

  def update
    @role = record
    @role.update(user: EndUser.find_by(user_name: end_user_params[:user_name]), **create_update_params)
    respond_with @role, location: course_tas_path(current_course)
  end

  def destroy
    @role = record
    begin
      @role.destroy!
    rescue ActiveRecord::DeleteRestrictionError => e
      flash_message(:error, I18n.t('flash.tas.destroy.restricted', user_name: @role.user_name, message: e.message))
      head :conflict
    rescue ActiveRecord::RecordNotDestroyed => e
      flash_message(:error, I18n.t('flash.tas.destroy.error', user_name: @role.user_name, message: e.message))
      head :bad_request
    else
      flash_now(:success, I18n.t('flash.tas.destroy.success', user_name: @role.user_name))
      head :no_content
    end
  end

  def download
    keys = [:user_name, :last_name, :first_name, :email]
    tas = current_course.tas.joins(:user).pluck_to_hash(*keys)
    case params[:format]
    when 'csv'
      output = MarkusCsv.generate(tas, &:values)
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
      data = process_file_upload(['.csv'])
    rescue StandardError => e
      flash_message(:error, e.message)
    else
      @current_job = UploadRolesJob.perform_later(Ta, current_course, data[:contents], data[:encoding])
      session[:job_id] = @current_job.job_id
    end
    redirect_to action: 'index'
  end

  private

  def create_update_params
    keys = [{ grader_permission_attributes: [:manage_assessments, :manage_submissions, :run_tests] }]
    keys << :hidden if allowed_to?(:manage_role_status?)
    params.require(:role).permit(*keys)
  end

  def end_user_params
    params.require(:role).require(:end_user).permit(:user_name)
  end

  def flash_interpolation_options
    { resource_name: @role.user&.user_name.blank? ? @role.model_name.human : @role.user_name,
      errors: @role.errors.full_messages.join('; ') }
  end
end
