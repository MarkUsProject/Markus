class PeerReviewPolicy < ApplicationPolicy
  alias_rule :index?, :populate?, :assign_groups?, to: :assign_reviewers?

  def assign_reviewers?
    user.admin? || (user.ta? && allowed_to?(:manage_reviewers?, with: GraderPermissionPolicy))
  end
end
