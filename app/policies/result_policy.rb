# Policy for Results controller.
class ResultPolicy < ApplicationPolicy
  # Only admin and authorized grader can delete the grace credit deduction.
  def delete_grace_period_deduction?
    user.admin? || (user.ta? && allowed_to?(:manage_extensions?, with: GraderPermissionPolicy))
  end
end
