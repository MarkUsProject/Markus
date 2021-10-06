# Manages actions relating to editing and modifying
# courses.
class CoursesController < ApplicationController
  before_action :set_course, only: [:show]
  before_action { authorize! }

  respond_to :html

  def index
    @courses = Course.all
    respond_with(@courses)
  end

  def show
    respond_with(@course)
  end

  private

  def set_course
    @course = Course.find(params[:id])
  end

  def course_params
    params.require(:course).permit(:name, :is_hidden)
  end
end
