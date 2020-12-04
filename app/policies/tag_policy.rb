# Tag policy class
class TagPolicy < ApplicationPolicy
  default_rule :manage?

  def manage?
    user.admin?
  end
end
