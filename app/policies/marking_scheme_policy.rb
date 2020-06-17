class MarkingSchemePolicy < ApplicationPolicy
  default_rule :manage?

  def manage?
    user.admin? || (user.ta? && allowed_to?(:manage_marking_schemes?, with: GraderPermissionPolicy))
  end
end
