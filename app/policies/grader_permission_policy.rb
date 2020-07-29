# Contains policy for all the grader permissions in the grader_permissions table
class GraderPermissionPolicy < ApplicationPolicy
  def create_delete_annotations?
    user.grader_permission.create_delete_annotations
  end

  def collect_all_submissions?
    user.grader_permission.collect_submissions
  end

  def manage_assignments?
    user.grader_permission.manage_assignments
  end

  def manage_exam_templates?
    user.grader_permission.manage_exam_templates
  end

  def release_unrelease_grades?
    user.grader_permission.release_unrelease_grades
  end

  def create_notes?
    user.grader_permission.create_notes
  end

  def manage_reviewers?
    user.grader_permission.manage_reviewers
  end

  def delete_grace_credit_deduction?
    user.grader_permission.delete_grace_period_deduction
  end

  def download_grades_report?
    user.grader_permission.download_grades_report
  end

  def manage_marking_schemes?
    user.grader_permission.manage_marking_schemes
  end

  def grader_run_tests?
    user.grader_permission.run_tests
  end
end
