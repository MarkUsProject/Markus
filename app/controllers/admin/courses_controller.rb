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
      @course.update(params.require(:course).permit(:name, :is_hidden, :display_name))
      respond_with @course, location: -> { edit_admin_course_path(@course) }
    end

    def edit
      @course = record
    end

    def update
      @course = record
      @course.update(params.require(:course).permit(:name, :is_hidden, :display_name))
      respond_with @course, location: -> { edit_admin_course_path(@course) }
    end
  end
end
