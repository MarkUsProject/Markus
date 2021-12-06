# Role policy class
class RolePolicy < ApplicationPolicy
  def manage?
    role.admin?
  end
end
