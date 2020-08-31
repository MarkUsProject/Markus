# Contains policy for all the grader permissions in the grader_permissions table
class GraderPermissionPolicy < ApplicationPolicy
  pre_check :allow_tas

  def manage_submissions?
    user.admin? || user.grader_permission.manage_submissions
  end

  def manage_assessments?
    user.admin? || user.grader_permission.manage_assessments
  end

  def run_tests?
    user.admin? || user.grader_permission.run_tests
  end

  private

  def allow_tas
    allow! if user.ta?
    deny! if user.student?
  end
end
