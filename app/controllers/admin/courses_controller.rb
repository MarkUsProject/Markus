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
      @course = Course.new
    end

    def create
      @course = Course.new
      @course.update(course_params)
      respond_with @course, location: -> { edit_admin_course_path(@course) }
    end

    def edit
      @course = record
    end

    def update
      @course = record
      @course.update(course_params)
      respond_with @course, location: -> { edit_admin_course_path(@course) }
    end

    private

    def course_params
      params.require(:course).permit(:name, :is_hidden, :display_name)
    end

    def flash_interpolation_options
      { resource_name: @course.name.presence || @course.model_name.human,
        errors: @course.errors.full_messages.join('; ') }
    end
  end
end
