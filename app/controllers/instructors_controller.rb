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
    @role = current_course.instructors.create(create_update_params)
    respond_with @role, location: course_instructors_path(current_course)
  end

  def edit
    @role = record
  end

  def update
    @role = record
    @role.update(create_update_params)
    respond_with @role, location: course_instructors_path(current_course)
  end

  def destroy
    @role = record
    begin
      @role.destroy!
    rescue ActiveRecord::DeleteRestrictionError => e
      flash_message(:error,
                    I18n.t('flash.instructors.destroy.restricted', user_name: @role.user_name, message: e.message))
      head :conflict
    rescue ActiveRecord::RecordNotDestroyed => e
      flash_message(:error,
                    I18n.t('flash.instructors.destroy.error', user_name: @role.user_name, message: e.message))
      head :bad_request
    else
      flash_now(:success, I18n.t('flash.instructors.destroy.success', user_name: @role.user_name))
      head :no_content
    end
  end

  private

  def create_update_params
    user = EndUser.find_by(user_name: end_user_params[:user_name])
    active_status = allowed_to?(:manage_role_status?) ? params.require(:role).permit(:hidden) : {}
    { user: user, **active_status }
  end

  def end_user_params
    params.require(:role).require(:end_user).permit(:user_name)
  end

  def flash_interpolation_options
    { resource_name: @role.user&.user_name.blank? ? @role.model_name.human : @role.user_name,
      errors: @role.errors.full_messages.join('; ') }
  end
end
