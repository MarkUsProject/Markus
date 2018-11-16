class SubmissionPolicy < ApplicationPolicy

  def run_tests?
    check?(:not_a_student?) && check?(:run_tests?, record.assignment) && check?(:before_release?)
  end

  def not_a_student?
    !user.student?
  end

  def before_release?
    !record.current_result.released_to_students
  end
end
