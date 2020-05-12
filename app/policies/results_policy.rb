class ResultsPolicy < ApplicationPolicy
  def delete_grace_period_deduction?
    user.admin? || (user.ta? && GraderPermission.find_by(user_id: user.id).delete_grace_period_deduction)
  end
end
