# Controller for managing Instructor roles
class InstructorsController < ApplicationController
  before_action { authorize! }

  layout 'assignment_content'

  responders :flash, :collection

  def index
    respond_to do |format|
      format.html
      format.json do
        instructors = current_course.instructors
                                    .joins(:user)
                                    .where(type: Instructor.name)
        render json: {
          data: instructors.pluck_to_hash(:id, :user_name, :first_name, :last_name, :email, :hidden),
          counts: {
            all: instructors.size,
            active: instructors.active.size,
            inactive: instructors.inactive.size
          }
        }
      end
    end
  end

  def new
    @role = current_course.instructors.new
  end

  def create
    user = EndUser.find_by(user_name: end_user_params[:user_name])
    @role = current_course.instructors.create(user: user)
    update_active_status
    respond_with @role, location: course_instructors_path(current_course)
  end

  def edit
    @role = record
  end

  def update
    @role = record
    @role.update(user: EndUser.find_by(user_name: end_user_params[:user_name]))
    update_active_status
    respond_with @role, location: course_instructors_path(current_course)
  end

  private

  def end_user_params
    params.require(:role).require(:end_user).permit(:user_name)
  end

  def flash_interpolation_options
    { resource_name: @role.user&.user_name.blank? ? @role.model_name.human : @role.user_name,
      errors: @role.errors.full_messages.join('; ') }
  end

  def update_active_status
    @role.update(params.require(:role).permit(:hidden)) if allowed_to?(:manage_user_status?)
  end
end
