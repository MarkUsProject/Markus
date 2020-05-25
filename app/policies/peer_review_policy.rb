class PeerReviewPolicy < ApplicationPolicy
  alias_rule :index?, :populate?, :assign_groups?, to: :assign_reviewers?

  def assign_reviewers?
    user.admin? || (user.ta? && GraderPermission.find_by(user_id: user.id).manage_reviewers)
  end
end
