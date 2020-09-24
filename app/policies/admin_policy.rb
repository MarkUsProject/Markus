# Admin policy class
class AdminPolicy < UserPolicy
  authorize :assignment, :submission, optional: true

  def run_tests?
    allowed = true
    allowed &&= (check?(:tests_enabled?, assignment) && check?(:test_groups_exist?, assignment)) unless assignment.nil?
    allowed &&= check?(:before_release?, submission) unless submission.nil?
    allowed
  end

  def manage_submissions?
    true
  end

  def manage_assessments?
    true
  end
end
