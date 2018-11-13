class SubmissionPolicy < ApplicationPolicy

  def run_tests?
    check?(:run_tests?, record.assignment) && check?(:before_release?)
  end

  def before_release?
    !record.current_result.released_to_students
  end
end
