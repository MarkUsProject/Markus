class GroupingPolicy < ApplicationPolicy
  authorize :membership, optional: true

  def run_tests?
    !user.student? || (
      check?(:member?) &&
      check?(:not_in_progress?) &&
      check?(:tokens_available?) &&
      check?(:before_due_date?)
    )
  end

  def member?
    record.accepted_students.include?(user)
  end

  def not_in_progress?
    !record.student_test_run_in_progress?
  end

  def tokens_available?
    record.test_tokens > 0 || record.assignment.unlimited_tokens
  end

  # Policies for group invitations.
  def invite_member?
    allowed_to?(:students_form_groups?) &&
      allowed_to?(:no_extension?) &&
      allowed_to?(:before_due_date?)
  end

  def students_form_groups?
    !record.assignment.invalid_override
  end

  def before_due_date?
    !record.past_collection_date?
  end

  def disinvite_member?
    user.user_name == record.inviter.user_name && membership.membership_status == StudentMembership::STATUSES[:pending]
  end

  def delete_rejected?
    user.user_name == record.inviter.user_name && membership.membership_status == StudentMembership::STATUSES[:rejected]
  end

  def destroy?
    check?(:deletable_by?) && check?(:no_submission?)
  end

  def deletable_by?
    record.deletable_by?(user)
  end

  def no_submission?
    !record.has_submission?
  end

  def no_extension?
    record.extension.nil?
  end

  def view_file_manager?
    user.student? &&
      !(record.assignment.scanned_exam? ||
        record.assignment.is_peer_review? ||
        (record.assignment.is_timed? && record.start_time.nil?))
  end

  def start_timed_assignment?
    user.student? &&
      record.start_time.nil? &&
      !record.past_collection_date? &&
      record.past_assessment_start_time?
  end
end
