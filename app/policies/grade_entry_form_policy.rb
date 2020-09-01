# Policy for Grade entry forms controller
class GradeEntryFormPolicy < ApplicationPolicy
  default_rule :manage?
  alias_rule :grades?, :view_summary?, :update_grade?, :get_mark_columns?,
             :populate_grades_table?, :download?, :upload?, to: :grading?

  # Only admin and grader can grade the students result.
  def grading?
    user.admin? || user.ta?
  end

  def manage?
    allowed_to?(:manage_assessments?, with: GraderPermissionPolicy)
  end

  def student_interface?
    user.student?
  end

  def update_grade_entry_students?
    allowed_to?(:manage_submissions?, with: GraderPermissionPolicy)
  end
end
