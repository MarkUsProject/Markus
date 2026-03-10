module Api
  # API controller for Courses
  class CoursesController < MainApiController
    include AutomatedTestsHelper::AutotestApi

    DEFAULT_FIELDS = [:id, :name, :is_hidden, :display_name, :start_at, :end_at].freeze

    def index
      if current_user.admin_user?
        courses = get_collection(Course)
      else
        courses = get_collection(current_user.visible_courses)
      end
      respond_to do |format|
        format.xml { render xml: courses.to_xml(only: DEFAULT_FIELDS, root: 'courses', skip_types: 'true') }
        format.json { render json: courses.to_json(only: DEFAULT_FIELDS) }
      end
    end

    def show
      course = current_course
      respond_to do |format|
        format.xml { render xml: course.to_xml(only: DEFAULT_FIELDS, root: 'course', skip_types: 'true') }
        format.json { render json: course.to_json(only: DEFAULT_FIELDS) }
      end
    end

    def create
      Course.create!(course_params)
    rescue ActiveRecord::SubclassNotFound, ActiveRecord::RecordInvalid => e
      render 'shared/http_status', locals: { code: '422', message: e.to_s }, status: :unprocessable_content
    rescue StandardError
      render 'shared/http_status', locals: { code: '500', message:
        HttpStatusHelper::ERROR_CODE['message']['500'] }, status: :internal_server_error
    else
      render 'shared/http_status', locals: { code: '200', message:
        HttpStatusHelper::ERROR_CODE['message']['200'] }, status: :ok
    end

    def update
      current_course.update!(course_params)
    rescue ActiveRecord::SubclassNotFound, ActiveRecord::RecordInvalid => e
      render 'shared/http_status', locals: { code: '422', message: e.to_s }, status: :unprocessable_content
    rescue StandardError
      render 'shared/http_status', locals: { code: '500', message:
        HttpStatusHelper::ERROR_CODE['message']['500'] }, status: :internal_server_error
    else
      render 'shared/http_status', locals: { code: '200', message:
        HttpStatusHelper::ERROR_CODE['message']['200'] }, status: :ok
    end

    def update_autotest_url
      AutotestResetUrlJob.perform_now(current_course, params[:url], request.protocol + request.host_with_port)
    rescue ActiveRecord::SubclassNotFound, ActiveRecord::RecordInvalid => e
      render 'shared/http_status', locals: { code: '422', message: e.to_s }, status: :unprocessable_content
    rescue StandardError
      render 'shared/http_status', locals: { code: '500', message:
        HttpStatusHelper::ERROR_CODE['message']['500'] }, status: :internal_server_error
    else
      render 'shared/http_status', locals: { code: '200', message:
        HttpStatusHelper::ERROR_CODE['message']['200'] }, status: :ok
    end

    def test_autotest_connection
      settings = current_course.autotest_setting
      if settings&.url
        begin
          get_schema(current_course.autotest_setting)
          render 'shared/http_status', locals: { code: '200', message:
            I18n.t('automated_tests.manage_connection.test_success', url: settings.url) }, status: :ok
        rescue JSON::ParserError
          render 'shared/http_status',
                 locals: { code: '500',
                           message: I18n.t('automated_tests.manage_connection.test_schema_failure',
                                           url: settings.url) },
                 status: :internal_server_error
        rescue StandardError => e
          render 'shared/http_status',
                 locals: { code: '500',
                           message: I18n.t('automated_tests.manage_connection.test_failure',
                                           url: settings.url,
                                           error: e.to_s) },
                 status: :internal_server_error
        end
      else
        render 'shared/http_status', locals: { code: '422', message:
          I18n.t('automated_tests.no_autotest_settings') }, status: :unprocessable_content
      end
    end

    def reset_autotest_connection
      settings = current_course.autotest_setting
      if settings&.url
        begin
          AutotestResetUrlJob.perform_now(current_course, settings.url,
                                          request.protocol + request.host_with_port, refresh: true)
          render 'shared/http_status', locals: { code: '200', message:
            HttpStatusHelper::ERROR_CODE['message']['200'] }, status: :ok
        rescue StandardError => e
          render 'shared/http_status', locals: { code: '500', message: e.to_s }, status: :internal_server_error
        end
      else
        render 'shared/http_status', locals: { code: '422', message:
          I18n.t('automated_tests.no_autotest_settings') }, status: :unprocessable_content
      end
    end

    private

    def check_course
      super unless action_name == 'index'
    end

    def course_params
      fields = [:name, :is_hidden, :display_name]
      if allowed_to?(:edit?, with: Admin::CoursePolicy)
        fields << :start_at
        fields << :end_at
      end
      params.permit(*fields)
    end

    protected

    def implicit_authorization_target
      Course
    end
  end
end
