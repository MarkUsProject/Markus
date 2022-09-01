module Api
  # API controller for Courses
  class CoursesController < MainApiController
    DEFAULT_FIELDS = [:id, :name, :is_hidden, :display_name].freeze

    def index
      if current_user.admin_user?
        courses = get_collection(Course)
      else
        courses = get_collection(
          Course.joins(:roles).where('roles.type': 'Instructor', 'roles.user_id': current_user.id)
        )
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
      Course.create!(params.permit(:name, :is_hidden, :display_name))
    rescue ActiveRecord::SubclassNotFound, ActiveRecord::RecordInvalid => e
      render 'shared/http_status', locals: { code: '422', message: e.to_s }, status: :unprocessable_entity
    rescue StandardError
      render 'shared/http_status', locals: { code: '500', message:
        HttpStatusHelper::ERROR_CODE['message']['500'] }, status: :internal_server_error
    else
      render 'shared/http_status', locals: { code: '200', message:
        HttpStatusHelper::ERROR_CODE['message']['200'] }, status: :ok
    end

    def update
      current_course.update!(params.permit(:name, :is_hidden, :display_name))
    rescue ActiveRecord::SubclassNotFound, ActiveRecord::RecordInvalid => e
      render 'shared/http_status', locals: { code: '422', message: e.to_s }, status: :unprocessable_entity
    rescue StandardError
      render 'shared/http_status', locals: { code: '500', message:
        HttpStatusHelper::ERROR_CODE['message']['500'] }, status: :internal_server_error
    else
      render 'shared/http_status', locals: { code: '200', message:
        HttpStatusHelper::ERROR_CODE['message']['200'] }, status: :ok
    end

    def update_autotest_url
      current_course.update_autotest_url(params[:url])
      raise current_course.errors.full_messages.join(' ') if current_course.reload.autotest_settings.url != params[:url]
    rescue ActiveRecord::SubclassNotFound, ActiveRecord::RecordInvalid => e
      render 'shared/http_status', locals: { code: '422', message: e.to_s }, status: :unprocessable_entity
    rescue StandardError
      render 'shared/http_status', locals: { code: '500', message:
        HttpStatusHelper::ERROR_CODE['message']['500'] }, status: :internal_server_error
    else
      render 'shared/http_status', locals: { code: '200', message:
        HttpStatusHelper::ERROR_CODE['message']['200'] }, status: :ok
    end

    private

    def check_course
      super unless action_name == 'index'
    end

    protected

    def implicit_authorization_target
      Course
    end
  end
end
