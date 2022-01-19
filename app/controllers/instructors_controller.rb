# Controller for managing Instructor roles
class InstructorsController < ApplicationController
  before_action { authorize! }

  layout 'assignment_content'

  responders :flash, :collection

  def index
    respond_to do |format|
      format.html
      format.json do
        data = current_course.instructors
                             .joins(:end_user)
                             .pluck_to_hash(:id, :user_name, :first_name, :last_name, :email)
        render json: data
      end
    end
  end

  def new
    @role = current_course.instructors.new
  end

  def create
    end_user = EndUser.find_by_user_name(end_user_params[:user_name])
    @role = current_course.instructors.create(end_user: end_user)
    respond_with @role, location: course_instructors_path(current_course)
  end

  def edit
    @role = record
  end

  def update
    @role = record
    @role.update(end_user: EndUser.find_by_user_name(end_user_params[:user_name]))
    respond_with @role, location: course_instructors_path(current_course)
  end

  private

  def end_user_params
    params.require(:role).require(:end_user).permit(:user_name)
  end

  def flash_interpolation_options
    { resource_name: @role.end_user&.user_name.blank? ? @role.model_name.human : @role.user_name,
      errors: @role.errors.full_messages.join('; ') }
  end
end
