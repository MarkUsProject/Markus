# Marking scheme policy class
class MarkingSchemePolicy < ApplicationPolicy
  default_rule :manage?

  def manage?
    user.admin?
  end
end
