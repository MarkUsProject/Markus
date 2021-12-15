# Role policy class
class RolePolicy < ApplicationPolicy
  def manage?
    role.instructor?
  end
end
