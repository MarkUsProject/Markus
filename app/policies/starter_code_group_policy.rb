class StarterCodeGroupPolicy < ApplicationPolicy
  default_rule :manage?

  def manage?
    user.admin?
  end
end
