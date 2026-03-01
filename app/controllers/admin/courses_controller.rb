module Admin
  class CoursesController < ApplicationController
    include AutomatedTestsHelper::AutotestApi

    DEFAULT_FIELDS = [:id, :name, :is_hidden, :display_name].freeze
    before_action { authorize! }

    respond_to :html
    layout 'assignment_content'

    def index
      respond_to do |format|
        format.html
        format.json { render json: Course.order(:created_at).to_json(only: DEFAULT_FIELDS) }
      end
    end

    def new
      @current_course = Course.new
    end

    def create
      @current_course = Course.create(course_create_params)
      update_autotest_url if @current_course.persisted?
      respond_with @current_course, location: -> { admin_courses_path }
    end

    def edit
      @lti_deployments = @current_course.lti_deployments
    end

    def update
      current_course.update(course_update_params)
      update_autotest_url
      respond_with @current_course, location: -> { edit_admin_course_path(@current_course) }
    end

    def test_autotest_connection
      settings = current_course.autotest_setting
      return head :unprocessable_content unless settings&.url
      begin
        get_schema(current_course.autotest_setting)
        flash_now(:success, I18n.t('automated_tests.manage_connection.test_success', url: settings.url))
      rescue JSON::ParserError
        flash_now(:error, I18n.t('automated_tests.manage_connection.test_schema_failure', url: settings.url))
      rescue StandardError => e
        flash_now(:error, I18n.t('automated_tests.manage_connection.test_failure', url: settings.url, error: e.to_s))
      end
      head :ok
    end

    def reset_autotest_connection
      settings = current_course.autotest_setting
      return head :unprocessable_content unless settings&.url
      @current_job = AutotestResetUrlJob.perform_later(current_course,
                                                       settings.url,
                                                       request.protocol + request.host_with_port,
                                                       refresh: true)
      session[:job_id] = @current_job.job_id if @current_job
      respond_with current_course, location: -> { edit_admin_course_path(current_course) }
    end

    def refresh_autotest_schema
      settings = current_course.autotest_setting
      if settings.nil?
        flash_message(:error, I18n.t('automated_tests.no_autotest_settings'))
        return respond_with current_course, location: -> { edit_admin_course_path(current_course) }
      end

      begin
        schema_json = get_schema(settings)
        settings.update!(schema: schema_json)
        flash_message(:success, I18n.t('automated_tests.manage_connection.refresh_schema_success'))
      rescue StandardError => e
        flash_message(:error, I18n.t('automated_tests.manage_connection.refresh_schema_failure', error: e.message))
      end
      respond_with current_course, location: -> { edit_admin_course_path(current_course) }
    end

    def destroy_lti_deployment
      deployment = LtiDeployment.find(params[:lti_deployment_id])
      deployment.destroy!
      redirect_to edit_admin_course_path(@current_course)
    end

    private

    def course_create_params
      params.require(:course).permit(:name, :is_hidden, :display_name, :max_file_size)
    end

    def course_update_params
      params.require(:course).permit(:is_hidden, :display_name, :max_file_size, :start_at, :end_at)
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
end
