# Tag policy class
class TagPolicy < ApplicationPolicy
  default_rule :manage?

  def manage?
    role.instructor?
  end
end
