class GradeEntryFormPolicy < ApplicationPolicy
  default_rule :manage?
  alias_rule [:edit?, :update?, :view_summary?], to: :modify?
  alias_rule [:new?, :create?], to: :new_form?


  def manage?
    user.admin? || user.ta?
  end

  def modify?
    user.admin?
  end

  def new_form?
    user.admin? || (user.ta? && GraderPermission.find_by(user_id: user.id).manage_grade_entry_forms)
  end

  def student_interface?
    user.student?
  end

  def update_grade_entry_students?
    user.admin? || (user.ta? && GraderPermission.find_by(user_id: user.id).manage_grade_entry_forms)
  end
end
