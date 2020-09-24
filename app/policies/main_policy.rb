# Main policy class
class MainPolicy < ApplicationPolicy
  authorize :real_user, optional: true
  default_rule :manage?

  def login_as?
    user.admin? || real_user&.admin?
  end

  def manage?
    user.is_a?(User)
  end
end
