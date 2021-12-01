# Marking scheme policy class
class MarkingSchemePolicy < ApplicationPolicy
  default_rule :manage?

  def manage?
    role.admin?
  end
end
