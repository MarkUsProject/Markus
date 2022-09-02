# Manages actions relating to editing and modifying
# courses.
class CoursesController < ApplicationController
  before_action { authorize! }

  respond_to :html
  layout 'assignment_content'

  def index
    # Force browsers not to cache the index page
    # to prevent attempting to render course_list
    # with cached HTML instead of requesting the json
    response.set_header('Cache-Control', 'no-store, must-revalidate')
    respond_to do |format|
      format.html { render :index }
      format.json do
        courses = current_user.visible_courses
                              .order('courses.name')
                              .pluck_to_hash('courses.id', 'courses.name',
                                             'courses.display_name', 'roles.type')
        render json: { data: courses }
      end
    end
  end

  def edit; end

  def update
    @current_course.update(params.require(:course).permit(:is_hidden, :display_name))
    update_autotest_url if allowed_to?(:edit?, with: Admin::CoursePolicy)
    respond_with @current_course, location: -> { edit_course_path(@current_course) }
  end

  def show
    if current_role.student? || current_role.ta?
      redirect_to course_assignments_path(@current_course.id)
    elsif current_role.instructor?
      @assignments = @current_course.assignments
      @grade_entry_forms = @current_course.grade_entry_forms
      @current_assignment = @current_course.get_current_assignment
      respond_with(@current_course)
    end
  end

  # Sets current_user to nil, which clears a role switch session (see role_switch)
  def clear_role_switch_session
    MarkusLogger.instance.log("Instructor '#{session[:real_user_name]}' logged out from '#{session[:user_name]}'.")
    session[:user_name] = nil
    session[:role_switch_course_id] = nil
    redirect_to action: 'show'
  end

  # Set the current_user. This allows an instructor to view their course from
  # the perspective of another (non-instructor) user.
  def switch_role
    if params[:effective_user_login].blank?
      render partial: 'role_switch_handler',
             formats: [:js], handlers: [:erb],
             locals: { error: I18n.t('main.username_not_blank') },
             status: :not_found
      return
    end

    found_user = User.find_by(user_name: params[:effective_user_login])
    found_role = Role.find_by(user: found_user, course: current_course)

    if found_role.nil?
      render partial: 'role_switch_handler',
             formats: [:js], handlers: [:erb],
             locals: { error: Settings.validate_user_not_allowed_message || I18n.t('main.login_failed') },
             status: :not_found
      return
    end

    # Check if the current instructor is trying to role switch as themselves
    if found_user.user_name == session[:real_user_name]
      render partial: 'role_switch_handler',
             formats: [:js], handlers: [:erb],
             locals: { error: I18n.t('main.cannot_role_switch_to_self') },
             status: :unprocessable_entity
      return
    end

    # Otherwise, check if the current instructor is trying to role switch as other instructors
    if found_role.instructor?
      render partial: 'role_switch_handler',
             formats: [:js], handlers: [:erb],
             locals: { error: I18n.t('main.cannot_role_switch_to_instructor') },
             status: :unprocessable_entity
      return
    end

    log_role_switch found_user
    self.current_user = found_user
    session[:role_switch_course_id] = current_course.id

    session[:redirect_uri] = nil
    refresh_timeout
    # All good, redirect to the main page of the viewer, discard
    # role switch modal
    render partial: 'role_switch_handler',
           formats: [:js], handlers: [:erb],
           locals: { error: nil }
  end

  def role_switch
    # dummy action for remote rjs calls
    # triggered by clicking on the "Switch role" link
    # please keep.
  end

  def download_assignments
    format = params[:format]
    case format
    when 'csv'
      output = current_course.get_assignment_list(format)
      send_data(output,
                filename: 'assignments.csv',
                type: 'text/csv',
                disposition: 'attachment')
    when 'yml'
      output = current_course.get_assignment_list(format)
      send_data(output,
                filename: 'assignments.yml',
                type: 'text/yml',
                disposition: 'attachment')
    else
      flash[:error] = t('download_errors.unrecognized_format', format: format)
      redirect_back(fallback_location: course_assignments_path(current_course))
    end
  end

  def upload_assignments
    begin
      data = process_file_upload
    rescue Psych::SyntaxError => e
      flash_message(:error, t('upload_errors.syntax_error', error: e.to_s))
    rescue StandardError => e
      flash_message(:error, e.message)
    else
      if data[:type] == '.csv'
        result = current_course.upload_assignment_list('csv', data[:file].read)
        flash_message(:error, result[:invalid_lines]) unless result[:invalid_lines].empty?
        flash_message(:success, result[:valid_lines]) unless result[:valid_lines].empty?
      elsif data[:type] == '.yml'
        result = current_course.upload_assignment_list('yml', data[:contents])
        if result.is_a?(StandardError)
          flash_message(:error, result.message)
        end
      end
    end
    redirect_back(fallback_location: course_assignments_path(current_course))
  end

  private

  def log_role_switch(found_user)
    # Log the date that the role switch occurred
    m_logger = MarkusLogger.instance
    if current_user != real_user
      # Log that the instructor dropped role of another user
      m_logger.log("Instructor '#{real_user.user_name}' logged out from '#{current_user.user_name}'.")
    end

    if found_user != real_user
      # Log that the instructor assumed role of another user
      m_logger.log("Instructor '#{real_user.user_name}' logged in as '#{found_user.user_name}'.")
    end
  end

  def course_params
    params.require(:course).permit(:name, :is_hidden)
  end

  def update_autotest_url
    url = params.require(:course).permit(:autotest_url)[:autotest_url]
    @current_job = AutotestResetUrlJob.perform_later(current_course, url, request.protocol + request.host_with_port)
    session[:job_id] = @current_job.job_id if @current_job
  end

  def flash_interpolation_options
    { resource_name: @current_course.name.presence || @current_course.model_name.human,
      errors: @current_course.errors.full_messages.join('; ') }
  end
end
