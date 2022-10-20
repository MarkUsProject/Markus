# Ta policy class
class TaPolicy < RolePolicy
  authorize :assignment, :submission, optional: true

  def run_tests?
    allowed = record.grader_permission.run_tests
    unless assignment.nil?
      allowed &&= check?(:tests_enabled?, assignment) && check?(:tests_set_up?, assignment)
    end
    allowed &&= check?(:before_release?, submission) unless submission.nil?
    allowed
  end

  def manage_submissions?
    role.grader_permission.manage_submissions
  end

  def manage_assessments?
    role.grader_permission.manage_assessments
  end

  def download?
    role.instructor?
  end

  def upload?
    role.instructor?
  end
end
