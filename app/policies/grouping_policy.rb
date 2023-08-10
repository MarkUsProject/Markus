# Grouping policy class
class GroupingPolicy < ApplicationPolicy
  authorize :membership, optional: true

  def member?
    record.accepted_students.include?(role)
  end

  def assigned_grader?
    role.ta? && record.tas.exists?(role.id)
  end

  def not_in_progress?
    !record.student_test_run_in_progress?
  end

  def tokens_available?
    record.test_tokens > 0 || record.assignment.unlimited_tokens
  end

  # Policies for group invitations.
  def invite_member?
    check?(:students_form_groups?) && check?(:no_extension?) && check?(:before_due_date?)
  end

  def students_form_groups?
    record.assignment.student_form_groups
  end

  def before_due_date?
    !record.past_collection_date?
  end

  def disinvite_member?
    role.user_name == record.inviter&.user_name && membership.membership_status == StudentMembership::STATUSES[:pending]
  end

  def delete_rejected?
    role.user_name == record.inviter&.user_name &&
        membership.membership_status == StudentMembership::STATUSES[:rejected]
  end

  def destroy?
    check?(:deletable_by?) && check?(:no_submission?)
  end

  def deletable_by?
    record.deletable_by?(role)
  end

  def no_submission?
    !record.has_submission?
  end

  def no_extension?
    record.extension.nil?
  end

  def view_file_manager?
    return false unless role.student?
    if record.assignment.scanned_exam? || record.assignment.is_peer_review?
      false
    elsif record.assignment.is_timed?
      !record.start_time.nil? || record.past_collection_date?
    else
      true
    end
  end

  def start_timed_assignment?
    role.student? &&
      record.start_time.nil? &&
      !record.past_collection_date? &&
      record.past_assessment_start_time?
  end

  def download_starter_file?
    return false unless role.student?
    return false unless check?(:see_hidden?, record.assignment)
    return false if !record.assignment.starter_files_after_due && record.past_collection_date?
    return true unless record.assignment.is_timed?
    !record.start_time.nil? || record.past_collection_date?
  end

  def populate_repo_with_starter_files?
    check?(:download_starter_file?) && check?(:access_repo?)
  end

  def access_repo?
    record.assignment.vcs_submit? && (!record.assignment.is_timed || !record.start_time.nil?)
  end
end
