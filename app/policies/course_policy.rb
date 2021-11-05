# Policy for courses controller.
class CoursePolicy < ApplicationPolicy
  default_rule :manage?

  def show?
    true
  end

  def index?
    true
  end

  def clear_role_switch_session?
    real_role.admin? && check?(:role_is_switched?)
  end

  def role_switch?
    real_role.admin? && !check?(:role_is_switched?)
  end

  def switch_role?
    real_role.admin? && !check?(:role_is_switched?)
  end
end
