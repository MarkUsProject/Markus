# Manages actions relating to editing and modifying
# courses.
class CoursesController < ApplicationController
  before_action :set_course, only: [:show]
  before_action { authorize! }

  respond_to :html

  def index
    @courses = Course.all
    respond_with(@courses, layout: false)
  end

  def show
    respond_with(@course)
  end

  # Sets current_user to nil, allowing an admin who had previously
  # switched roles to view the course from the perspective of another user
  def clear_role_switch_session
    MarkusLogger.instance.log("Admin '#{session[:real_user_name]}' logged out from '#{session[:user_name]}'.")
    session[:user_name] = nil
    session[:role_switch_course_id] = nil
    redirect_to action: 'show'
  end

  # Set the current_user. This allows an admin to view their course from
  # the perspective of another (non-admin) user.
  def switch_role
    if params[:effective_user_login].blank?
      render partial: 'role_switch_handler',
             formats: [:js], handlers: [:erb],
             locals: { error: I18n.t('main.username_not_blank') }
      return
    end

    found_user = User.find_by_user_name(params[:effective_user_login])
    found_role = Role.find_by(human: found_user, course: current_course)

    if found_role.nil? || found_role.admin?
      render partial: 'role_switch_handler',
             formats: [:js], handlers: [:erb],
             locals: { error: Settings.validate_user_not_allowed_message || I18n.t('main.login_failed') }
      return
    end

    # Check if an admin trying to login as the current user or themselves
    if found_user.user_name == session[:user_name] || found_user.user_name == session[:real_user_name]
      # error
      render partial: 'role_switch_handler',
             formats: [:js], handlers: [:erb],
             # TODO: put better error message
             locals: { error: I18n.t('main.login_failed') }
      return
    end

    log_role_switch found_user
    self.current_user = found_user
    session[:role_switch_course_id] = current_course.id

    session[:redirect_uri] = nil
    refresh_timeout
    # All good, redirect to the main page of the viewer, discard
    # role switch modal
    render partial: 'role_switch_handler',
           formats: [:js], handlers: [:erb],
           locals: { error: nil }
  end

  def role_switch
    # dummy action for remote rjs calls
    # triggered by clicking on the "Switch role" link
    # please keep.
  end

  private

  def set_course
    @course = Course.find(params[:id])
  end

  def course_params
    params.require(:course).permit(:name, :is_hidden)
  end
end
