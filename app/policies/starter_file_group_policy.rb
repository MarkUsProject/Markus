# Policy for starter file groups
class StarterFileGroupPolicy < ApplicationPolicy
  default_rule :manage?

  def manage?
    check?(:manage_assessments?, role)
  end
end
