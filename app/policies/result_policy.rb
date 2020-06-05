class ResultPolicy < ApplicationPolicy
  def delete_grace_period_deduction?
    user.admin? || (user.ta? && allowed_to?(:delete_grace_credit_deduction?, with: GraderPermissionPolicy))
  end
end
