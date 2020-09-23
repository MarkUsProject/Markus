# Contains policy for all the grader permissions in the grader_permissions table
class GraderPermissionPolicy < ApplicationPolicy
  pre_check :only_tas

  def manage_submissions?
    user.grader_permission.manage_submissions
  end

  def manage_assessments?
    user.grader_permission.manage_assessments
  end

  def run_tests?
    user.grader_permission.run_tests
  end

  private

  def only_tas
    return allow! if user.admin?
    deny! if user.student?
  end
end
