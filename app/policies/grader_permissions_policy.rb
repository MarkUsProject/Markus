class GraderPermissionsPolicy < ApplicationPolicy
  def collect_all_submissions?
    GraderPermissions.find_by(user_id: user.id).collect_submissions
  end

  def manage_assignments?
    GraderPermissions.find_by(user_id: user.id).manage_assignments
  end

  def manage_exam_templates?
    GraderPermissions.find_by(user_id: user.id).manage_exam_templates
  end

  def manage_grade_entry_forms?
    GraderPermissions.find_by(user_id: user.id).manage_grade_entry_forms
  end

  def release_unrelease_grades?
    GraderPermissions.find_by(user_id: user.id).release_unrelease_grades
  end

  def create_notes?
    GraderPermissions.find_by(user_id: user.id).create_notes
  end

  def manage_reviewers?
    GraderPermissions.find_by(user_id: user.id).manage_reviewers
  end

  def delete_grace_credit_deduction?
    GraderPermissions.find_by(user_id: user.id).delete_grace_period_deduction
  end
end
