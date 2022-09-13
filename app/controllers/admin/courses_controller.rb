module Admin
  class CoursesController < ApplicationController
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
      respond_with @current_course, location: -> { admin_courses_path }
    end

    def edit; end

    def update
      current_course.update(course_update_params)
      respond_with @current_course, location: -> { edit_admin_course_path(@current_course) }
    end

    private

    def course_create_params
      params.require(:course).permit(:name, :is_hidden, :display_name, :max_file_size)
    end

    def course_update_params
      params.require(:course).permit(:is_hidden, :display_name, :max_file_size)
    end

    def flash_interpolation_options
      { resource_name: @current_course.name.presence || @current_course.model_name.human,
        errors: @current_course.errors.full_messages.join('; ') }
    end
  end
end
