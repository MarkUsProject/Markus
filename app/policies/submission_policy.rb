# Submission policy class
class SubmissionPolicy < ApplicationPolicy
  alias_rule :manually_collect_and_begin_grading?, :collect_submissions?, :update_submissions?, to: :manage?
  alias_rule :index?, :browse?, :set_result_marking_state?, :revisions?, :repo_browser?,
             :zip_groupings_files?, :download_zipped_file?, :download_summary?, to: :manage_files?
  alias_rule :download?, :downloads?, :get_file?, :populate_file_manager?, :update_files?, to: :view_files?
  alias_rule :download_file_zip?, to: :download_file?

  authorize :from_codeviewer, :select_file, optional: true

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

  def notebook_content?
    Rails.application.config.nbconvert_enabled && check?(:view_files?)
  end

  def run_tests?
    check?(:run_tests?, role)
  end

  def download_file?
    check?(:manage_submissions?, role) || check?(:assigned_grader?, record.grouping) || (
      from_codeviewer && role.is_reviewer_for?(record.grouping.assignment.pr_assignment, record.current_result)
    ) || (
      record.grouping.accepted_students.ids.include?(role.id) && (
        select_file.nil? || select_file.submission == record
      )
    )
  end

  def before_release?
    !record.current_result.released_to_students
  end
end
