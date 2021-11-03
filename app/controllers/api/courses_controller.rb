module Api
  # API controller for Courses
  class CoursesController < MainApiController
    DEFAULT_FIELDS = [:id, :name, :is_hidden, :display_name].freeze

    def index
      courses = get_collection(Course.joins(:roles).where('roles.type': 'Admin', 'roles.user_id': current_user.id))
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
