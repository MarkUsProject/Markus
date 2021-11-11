# Section policy class
class SectionPolicy < ApplicationPolicy
  default_rule :manage?

  def manage?
    role.admin?
  end
end
