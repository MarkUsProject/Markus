class CriterionPolicy < ApplicationPolicy
  default_rule :manage?

  def manage?
    check?(:manage_assessments?, user)
  end
end
