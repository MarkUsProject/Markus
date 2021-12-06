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
    human = Human.find_by_user_name(human_params[:user_name])
    @role = current_course.admins.create(human: human)
    respond_with @role, location: course_admins_path(current_course)
  end

  def edit
    @role = record
  end

  def update
    @role = record
    @role.update(human: Human.find_by_user_name(human_params[:user_name]))
    respond_with @role, location: course_admins_path(current_course)
  end

  private

  def human_params
    params.require(:role).require(:human).permit(:user_name)
  end
end
