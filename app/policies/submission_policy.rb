class SubmissionPolicy < ApplicationPolicy
  alias_rule :manually_collect_and_begin_grading?, :collect_submissions?, :update_submissions?, to: :manage?

  def get_feedback_file?
    grouping = record.grouping
    if user.student?
      !grouping.membership_status(user).nil? && record.current_result.released_to_students
    elsif user.ta?
      grouping.tas.pluck(:id).include? user.id
    else
      true
    end
  end

  def run_tests?
    check?(:not_a_student?) &&
    check?(:before_release?)
  end

  def manage_subdirectories?
    check?(:not_a_student?)
  end

  def not_a_student?
    !user.student?
  end

  def before_release?
    !record.current_result.released_to_students
  end

  def manage?
    allowed_to?(:manage_submissions?, with: GraderPermissionPolicy)
  end

  def allowed_to_run_tests?
    allowed_to?(:grader_run_tests?, with: GraderPermissionPolicy) && record.enable_test
  end
end
