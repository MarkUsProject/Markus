# Policy for Peer reviews controller
class PeerReviewPolicy < ApplicationPolicy
  default_rule :manage?
  alias_rule :index?, :populate?, :assign_groups?, to: :manage_reviewers?
  alias_rule :list_reviews?, :show_reviews?, :show_result?, to: :view?

  def view?
    true
  end

  def manage?
    user.admin?
  end

  # Only admin and authorized grader can manage reviewers.
  def manage_reviewers?
    check?(:manage_assessments?, user)
  end
end
