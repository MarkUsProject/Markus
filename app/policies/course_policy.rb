# Policy for courses controller.
class CoursePolicy < ApplicationPolicy
  default_rule :manage?
  alias_rule :clear_role_switch_session?, to: :role_is_switched?

  def show?
    role.admin?
  end

  def index?
    true
  end

  def role_switch?
    real_role.admin? && !check?(:role_is_switched?)
  end

  def switch_role?
    real_role.admin? && !check?(:role_is_switched?)
  end
end
