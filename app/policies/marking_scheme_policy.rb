# Policy for Marking schemes controller.
class MarkingSchemePolicy < ApplicationPolicy
  # Default rule: Only admin and authorized grader can manage marking schemes.
  default_rule :manage?

  def manage?
    user.admin? || (user.ta? && allowed_to?(:manage_marking_schemes?, with: GraderPermissionPolicy))
  end
end
