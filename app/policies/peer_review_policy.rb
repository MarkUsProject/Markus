# Policy for Peer reviews controller
class PeerReviewPolicy < ApplicationPolicy
  default_rule :manage?
  alias_rule :index?, :populate?, :assign_groups?, to: :manage_reviewers?
  alias_rule :list_reviews?, :show_reviews?, :show_result?, to: :view?
  alias_rule :populate_table?, to: :view_table?

  def view?
    true
  end

  # The table pairs every reviewer with a reviewee and a grade.
  def view_table?
    role.instructor? || role.ta?
  end

  def manage?
    role.instructor?
  end

  # Only instructor and authorized grader can manage reviewers.
  def manage_reviewers?
    check?(:manage_assessments?, role)
  end
end
