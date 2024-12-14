# Ta policy class
class TaPolicy < RolePolicy
  authorize :assignment, :criterion_id, :submission, optional: true

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

  def destroy?
    role.instructor?
  end

  def upload?
    role.instructor?
  end

  def manage_role_status?
    role.instructor?
  end

  def assigned_to_criterion?
    role.criterion_ta_associations.where(criterion_id: criterion_id).present?
  end
end
