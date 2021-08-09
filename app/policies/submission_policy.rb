# Submission policy class
class SubmissionPolicy < ApplicationPolicy
  alias_rule :manually_collect_and_begin_grading?, :collect_submissions?, :update_submissions?, to: :manage?
  alias_rule :index?, :browse?, :set_result_marking_state?, :revisions?, :repo_browser?,
             :zip_groupings_files?, :download_zipped_file?, :download_summary?, to: :manage_files?
  alias_rule :download?, :notebook_content?, :downloads?, :get_file?, :populate_file_manager?,
             :update_files?, to: :view_files?

  def manage?
    check?(:manage_submissions?, user)
  end

  def file_manager?
    user.student?
  end

  def manage_files?
    user.admin? || user.ta?
  end

  def manage_subdirectories?
    user.admin? || user.ta?
  end

  def view_files?
    true
  end

  def before_release?
    !record.current_result.released_to_students
  end
end
