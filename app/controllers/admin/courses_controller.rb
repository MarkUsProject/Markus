module Admin
  class CoursesController < ApplicationController
    DEFAULT_FIELDS = [:id, :name, :is_hidden, :display_name].freeze
    before_action { authorize! }

    respond_to :html
    layout 'assignment_content'

    def index
      respond_to do |format|
        format.html
        format.json { render json: Course.order('id').to_json(only: DEFAULT_FIELDS) }
      end
    end

    def edit
      @course = record
    end

    def update
      @course = record
      @course.update!(params.require(:course).permit(:name, :is_hidden, :display_name))
      respond_with @course
    end
  end
end
