# Result policy class
class ResultPolicy < ApplicationPolicy
  default_rule :manage?
  alias_rule :get_test_runs_instructors_released?, to: :view_marks?
  alias_rule :create?, :add_extra_mark?, :remove_extra_mark?, :get_test_runs_instructors?, :print?,
             :add_tag?, :remove_tag?, :revert_to_automatic_deductions?, :random_incomplete_submission?, to: :grade?
  alias_rule :show?, :get_annotations?, to: :view?
  alias_rule :edit?, :toggle_marking_state?, :update_overall_comment?, :next_grouping?,
             :get_filtered_grouping_ids?, to: :review?
  alias_rule :refresh_view_tokens?, :update_view_token_expiry?, to: :set_released_to_students?

  authorize :view_token, optional: true
  authorize :criterion_id, optional: true

  def view?
    check?(:manage_submissions?, role) || check?(:assigned_grader?, record.grouping) ||
      (!record.grouping.assignment.release_with_urls && check?(:member?, record.submission.grouping)) ||
      check?(:view_with_result_token?) ||
      role.is_reviewer_for?(record.grouping.assignment.pr_assignment, record)
  end

  def view_marks?
    check?(:member?, record.submission.grouping) &&
      (!record.grouping.assignment.release_with_urls || check?(:view_with_result_token?))
  end

  def view_token_check?
    check?(:member?, record.submission.grouping) &&
      record.grouping.assignment.release_with_urls &&
      !record.view_token_expired?
  end

  def run_tests?
    submission = record.submission
    grouping = submission.grouping
    assignment = grouping.assignment
    check?(:run_tests?, role, context: { role: role,
                                         assignment: assignment,
                                         grouping: grouping,
                                         submission: submission })
  end

  def grade?
    check?(:manage_submissions?, role) || check?(:assigned_grader?, record.grouping)
  end

  def review?
    check?(:manage_submissions?, role) || check?(:assigned_grader?, record.grouping) || (
      record&.submission&.assignment&.has_peer_review &&
          role.is_reviewer_for?(record&.submission&.assignment&.pr_assignment, record)
    )
  end

  def update_mark?
    assignment = record.grouping.assignment
    if !check?(:manage_submissions?, role) && assignment.assign_graders_to_criteria && role.ta?
      check?(:review?) && check?(:assigned_to_criterion?, with: TaPolicy)
    else
      check?(:review?)
    end
  end

  def set_released_to_students?
    check?(:manage_submissions?, role)
  end

  def manage?
    role.instructor?
  end

  # This is a separate policy function because it reports a specific error message on failure
  def view_with_result_token?
    check?(:member?, record.submission.grouping) && record.view_token == view_token && !record.view_token_expired?
  end
end
