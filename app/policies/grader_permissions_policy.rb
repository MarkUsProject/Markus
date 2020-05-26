class GraderPermissionsPolicy < ApplicationPolicy
  def collect_all_submissions?
    GraderPermission.find_by(user_id: user.id).manually_collect_and_begin_grading
  end

  def manage_assignments?
    GraderPermission.find_by(user_id: user.id).create_assignments
  end

  def manage_exam_templates?
    GraderPermission.find_by(user_id: user.id).manage_exam_templates
  end

  def manage_grade_entry_forms?
    GraderPermission.find_by(user_id: user.id).manage_grade_entry_forms
  end

  def release_unrelease_grades?
    GraderPermission.find_by(user_id: user.id).update_grade_entry_students
  end

  def create_notes?
    GraderPermission.find_by(user_id: user.id).create_notes
  end

  def manage_reviewers?
    GraderPermission.find_by(user_id: user.id).manage_reviewers
  end

  def delete_grace_credit_deduction?
    GraderPermission.find_by(user_id: user.id).delete_grace_period_deduction
  end
end
