# Policy for courses controller.
class CoursePolicy < ApplicationPolicy
  skip_pre_check :role_exists?

  default_rule :manage?
  alias_rule :clear_role_switch_session?, to: :role_is_switched?

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
end
