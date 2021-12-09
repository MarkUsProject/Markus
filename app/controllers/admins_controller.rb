class AdminsController < ApplicationController
  before_action { authorize! }

  layout 'assignment_content'

  responders :flash, :collection

  def index
    respond_to do |format|
      format.html
      format.json {
        render json: current_course.admins
                                   .joins(:end_user)
                                   .pluck_to_hash(:id, :user_name, :first_name, :last_name, :email)
      }
    end
  end

  def new
    @role = current_course.admins.new
  end

  def create
    end_user = EndUser.find_by_user_name(end_user_params[:user_name])
    @role = current_course.admins.create(end_user: end_user)
    respond_with @role, location: course_admins_path(current_course)
  end

  def edit
    @role = record
  end

  def update
    @role = record
    @role.update(end_user: EndUser.find_by_user_name(end_user_params[:user_name]))
    respond_with @role, location: course_admins_path(current_course)
  end

  private

  def end_user_params
    params.require(:role).require(:end_user).permit(:user_name)
  end
end
