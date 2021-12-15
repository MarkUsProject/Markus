# Section policy class
class SectionPolicy < ApplicationPolicy
  default_rule :manage?

  def manage?
    role.instructor?
  end
end
