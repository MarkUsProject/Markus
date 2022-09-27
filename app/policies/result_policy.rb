# Result policy class
class ResultPolicy < ApplicationPolicy
  default_rule :manage?
  alias_rule :update_remark_request?, :cancel_remark_request?, :get_test_runs_instructors_released?,
             :view_token_check?, to: :student?
  alias_rule :create?, :add_extra_mark?, :remove_extra_mark?, :get_test_runs_instructors?,
             :add_tag?, :remove_tag?, :revert_to_automatic_deductions?, to: :grade?
  alias_rule :show?, :view_marks?, :get_annotations?, :show?, to: :view?
  alias_rule :download_zip?, to: :download?
  alias_rule :edit?, :update_mark?, :toggle_marking_state?, :update_overall_comment?, :next_grouping?, to: :review?
  alias_rule :refresh_view_tokens?, :update_view_token_expiry?, to: :set_released_to_students?

  authorize :from_codeviewer, :select_file, :view_token, optional: true

  def view?
    check?(:view_without_result_token?) || check?(:view_with_result_token?)
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
    role.instructor? || role.ta?
  end

  def review?
    role.instructor? || role.ta? || (
      record&.submission&.assignment&.has_peer_review &&
          role.is_reviewer_for?(record&.submission&.assignment&.pr_assignment, record)
    )
  end

  def set_released_to_students?
    check?(:manage_submissions?, role)
  end

  def manage?
    role.instructor?
  end

  def download?
    role.instructor? || role.ta? || (
      from_codeviewer && role.is_reviewer_for?(record.submission.grouping.assignment.pr_assignment, record)
    ) || (
      record.submission.grouping.accepted_students.ids.include?(role.id) && (
        select_file.nil? || select_file.submission == record.submission
      )
    )
  end

  def view_without_result_token?
    role.instructor? || role.ta? || !record.grouping.assignment.release_with_urls
  end

  def submit_result_token?
    !check?(:view_without_result_token?) && !record.view_token_expired?
  end

  # This is a separate policy function because it reports a specific error message on failure
  def view_with_result_token?
    record.view_token == view_token && !record.view_token_expired?
  end
end
