class SubmissionPolicy < ApplicationPolicy

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
end
