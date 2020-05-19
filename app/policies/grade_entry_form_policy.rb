class GradeEntryFormPolicy < ApplicationPolicy
  default_rule :grading?
  alias_rule [:new?, :create?, :edit?, :update?], to: :manage?

  def grading?
    user.admin? || user.ta?
  end

  def manage?
    user.admin? || (user.ta? && GraderPermission.find_by(user_id: user.id).manage_grade_entry_forms)
  end

  def student_interface?
    user.student?
  end

  def update_grade_entry_students?
    user.admin? || (user.ta? && GraderPermission.find_by(user_id: user.id).update_grade_entry_students)
  end
end
