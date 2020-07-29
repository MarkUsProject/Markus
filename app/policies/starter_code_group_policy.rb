# Policy for starter code groups
class StarterCodeGroupPolicy < ApplicationPolicy
  default_rule :manage?

  def manage?
    user.admin?
  end
end
