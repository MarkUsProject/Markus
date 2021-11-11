# Tag policy class
class TagPolicy < ApplicationPolicy
  default_rule :manage?

  def manage?
    role.admin?
  end
end
