# Policy for starter file groups
class StarterFileGroupPolicy < ApplicationPolicy
  default_rule :manage?

  def manage?
    user.admin?
  end
end
