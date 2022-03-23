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

    def edit
      @course = record
    end

    def update
      @course = record
      update_course(@course)
      respond_with @course, location: -> { edit_admin_course_path(@course) }
    end

    private

    # Helper for update and create course methods that updates the given +course+ attributes
    # specified from the parameters of the request.
    def update_course(course)
      course.transaction do
        course.update(params.require(:course).permit(:name, :is_hidden, :display_name))
        course.save!
      end
    rescue StandardError
      # Do nothing
    end
  end
end
