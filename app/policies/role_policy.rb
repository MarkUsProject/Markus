# Role policy class
class RolePolicy < ApplicationPolicy
  def create?
    role.admin?
  end
  def new?
    role.admin?
  end
  def index?
    role.admin?
  end
end
