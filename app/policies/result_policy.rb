# Result policy class
class ResultPolicy < ApplicationPolicy
  default_rule :manage?
  alias_rule :update_remark_request?, :cancel_remark_request?, :get_test_runs_instructors_released?, to: :student?
  alias_rule :create?, :add_extra_mark?, :remove_extra_mark?, :get_test_runs_instructors?,
             :add_tag?, :remove_tag?, :revert_to_automatic_deductions?, to: :grade?
  alias_rule :show?, :view_marks?, :get_annotations?, :show?, to: :view?
  alias_rule :download_zip?, to: :download?
  alias_rule :edit?, :update_mark?, :toggle_marking_state?, :update_overall_comment?, :next_grouping?, to: :review?

  authorize :from_codeviewer, :select_file, optional: true

  def view?
    check?(:manage_submissions?, role) || check?(:assigned_grader?, record.grouping) ||
      (!record.grouping.assignment.release_with_urls && check?(:member?, record.submission.grouping))
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

  def set_released_to_students?
    check?(:review?) && check?(:manage_submissions?, role)
  end

  def manage?
    role.instructor?
  end

  def download?
    check?(:manage_submissions?, role) || check?(:assigned_grader?, record.grouping) || (
      from_codeviewer && role.is_reviewer_for?(record.submission.grouping.assignment.pr_assignment, record)
    ) || (
      record.submission.grouping.accepted_students.ids.include?(role.id) && (
        select_file.nil? || select_file.submission == record.submission
      )
    )
  end
end
