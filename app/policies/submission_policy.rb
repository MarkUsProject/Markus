class SubmissionPolicy < ApplicationPolicy

  def run_tests?
    check?(:run_tests?, record.grouping) &&
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
