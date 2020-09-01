# Policy for Peer reviews controller
class PeerReviewPolicy < ApplicationPolicy
  default_rule :manage?
  alias_rule :index?, :populate?, :assign_groups?, to: :manage_reviewers?

  def manage?
    user.admin?
  end

  # Only admin and authorized grader can manage reviewers.
  def manage_reviewers?
    allowed_to?(:manage_assessments?, with: GraderPermissionPolicy)
  end
end
