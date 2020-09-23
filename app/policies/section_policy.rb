class SectionPolicy < ApplicationPolicy
  default_rule :manage?

  def manage?
    user.admin?
  end
end
