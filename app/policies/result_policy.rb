# Result policy class
class ResultPolicy < ApplicationPolicy
  default_rule :manage?
  alias_rule :update_remark_request?, :cancel_remark_request?, :get_test_runs_instructors_released?, to: :student?
  alias_rule :create?, :add_extra_mark?, :remove_extra_mark?, :get_test_runs_instructors?,
             :add_tag?, :remove_tag?, :revert_to_automatic_deductions?, to: :grade?
  alias_rule :show?, :download?, :download_zip?, :view_marks?, :get_annotations?, :show?, to: :view?
  alias_rule :edit?, :update_mark?, :toggle_marking_state?, :update_overall_comment?, :next_grouping?, to: :review?

  def view?
    true
  end

  def run_tests?
    submission = record.submission
    grouping = submission.grouping
    assignment = grouping.assignment
    check?(:run_tests?, user, context: { user: user,
                                         assignment: assignment,
                                         grouping: grouping,
                                         submission: submission })
  end

  def grade?
    user.admin? || user.ta?
  end

  def review?
    user.admin? || user.ta? || (
      record&.submission&.assignment&.has_peer_review &&
        user.is_reviewer_for?(record&.submission&.assignment&.pr_assignment, record)
    )
  end

  def manage?
    user.admin?
  end
end
