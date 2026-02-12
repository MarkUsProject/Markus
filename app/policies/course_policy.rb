# Policy for courses controller.
class CoursePolicy < ApplicationPolicy
  skip_pre_check :role_exists?, only: [:index?, :manage_lti_deployments?]
  skip_pre_check :role_is_hidden?, only: :clear_role_switch_session?

  default_rule :manage?
  alias_rule :clear_role_switch_session?, to: :role_is_switched?
  alias_rule :destroy_lti_deployment?, :sync_roster?, :lti_deployments?, to: :manage_lti_deployments?

  def show?
    role.instructor? || role.student? || role.ta?
  end

  def index?
    user.end_user?
  end

  def edit?
    role.instructor?
  end

  def update?
    role.instructor?
  end

  def role_switch?
    real_role&.instructor? && !check?(:role_is_switched?)
  end

  def switch_role?
    real_role.instructor? && !check?(:role_is_switched?)
  end

  def download_assignments?
    check?(:manage_assessments?, role)
  end

  def upload_assignments?
    check?(:manage_assessments?, role)
  end

  def manage_lti_deployments?
    user.admin_user? || Instructor.exists?(user: user, course: record)
  end

  def refresh_autotest_schema?
    edit?
  end
end
