class JobMessagePolicy < ApplicationPolicy
  default_rule :manage?

  def manage?
    user.admin? || user.ta?
  end
end
