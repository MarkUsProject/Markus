# Submission policy class
class SubmissionPolicy < ApplicationPolicy
  alias_rule :manually_collect_and_begin_grading?, :collect_submissions?, :update_submissions?, to: :manage?
  alias_rule :index?, :browse?, :set_result_marking_state?, :revisions?, :repo_browser?,
             :zip_groupings_files?, :download_zipped_file?, :download_summary?, to: :manage_files?
  alias_rule :download?, :downloads?, :populate_file_manager?, :update_files?, to: :view_files?
  alias_rule :download_file_zip?, to: :download_file?
  alias_rule :update_remark_request?, :cancel_remark_request?, to: :change_remark_status?

  authorize :from_codeviewer, :view_token, optional: true

  def manage?
    check?(:manage_submissions?, role)
  end

  def file_manager?
    role.student?
  end

  def manage_files?
    role.instructor? || role.ta?
  end

  def manage_subdirectories?
    true
  end

  def view_files?
    true
  end

  def run_tests?
    check?(:run_tests?, role)
  end

  def download_file?
    check?(:manage_submissions?, role) || check?(:assigned_grader?, record.grouping) || (
      from_codeviewer && role.is_a_reviewer_for_submission?(record)
    ) ||
      record.grouping.accepted_students.ids.include?(role.id)
  end

  def change_remark_status?
    check?(:member?, record.grouping) &&
      (!record.grouping.assignment.release_with_urls || check?(:view_with_result_token?))
  end

  # This is a separate policy function because it reports a specific error message on failure
  def view_with_result_token?
    check?(:member?,
           record.current_result.grouping) && record.current_result.view_token == view_token &&
      !record.current_result.view_token_expired?
  end

  def before_release?
    !record.current_result.released_to_students
  end
end
