# Ta policy class
class TaPolicy < UserPolicy
  authorize :assignment, :submission, optional: true

  def run_tests?
    allowed = record.grader_permission.run_tests
    unless assignment.nil?
      allowed &&= check?(:tests_enabled?, assignment) && check?(:test_groups_exist?, assignment)
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
end
