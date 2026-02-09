# Instructor policy class
class InstructorPolicy < RolePolicy
  authorize :assignment, :submission, optional: true

  def run_tests?
    allowed = true
    allowed &&= check?(:tests_enabled?, assignment) && check?(:tests_set_up?, assignment) unless assignment.nil?
    allowed &&= check?(:before_release?, submission) unless submission.nil?
    allowed
  end

  def manage_submissions?
    true
  end

  def manage_assessments?
    true
  end

  def destroy?
    user.admin_user?
  end

  def manage_role_status?
    user.admin_user?
  end
end
