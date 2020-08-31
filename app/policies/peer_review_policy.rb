# Policy for Peer reviews controller
class PeerReviewPolicy < ApplicationPolicy
  default_rule :manage?

  # Only admin and authorized grader can manage reviewers.
  def manage?
    allowed_to?(:manage_assessments?, with: GraderPermissionPolicy)
  end
end
