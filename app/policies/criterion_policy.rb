# Criterion policy class
class CriterionPolicy < ApplicationPolicy
  default_rule :manage?

  def manage?
    check?(:manage_assessments?, role)
  end
end
