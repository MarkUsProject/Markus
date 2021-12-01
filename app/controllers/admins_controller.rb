class AdminsController < ApplicationController
  before_action { authorize! }

  layout 'assignment_content'

  responders :flash, :collection

  def index
    respond_to do |format|
      format.html
      format.json {
        render json: current_course.admins.joins(:human).pluck_to_hash(:id, :user_name, :first_name, :last_name, :email)
      }
    end
  end

  def new
    @role = current_course.admins.new
  end

  def create
    human = Human.find_by_user_name(params[:user_name])
    @role = current_course.admins.create(human: human)
    respond_with @role, location: course_admins_path(current_course)
  end

  private

  def flash_interpolation_options
    { resource_name: @role.human&.user_name.blank? ? @role.model_name.human : @role.user_name,
      errors: @role.errors.full_messages.join('; ') }
  end
end
