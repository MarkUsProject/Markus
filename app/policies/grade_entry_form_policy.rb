# Policy for Grade entry forms controller
class GradeEntryFormPolicy < ApplicationPolicy
  default_rule :grading?
  alias_rule :new?, :create?, :edit?, :update?, to: :manage?

  # Only admin and grader can grade the students result.
  def grading?
    user.admin? || user.ta?
  end

  def manage?
    user.admin? || (user.ta? && allowed_to?(:manage_assessments?, with: GraderPermissionPolicy))
  end

  def student_interface?
    user.student?
  end

  def update_grade_entry_students?
    user.admin? || (user.ta? && allowed_to?(:manage_submissions?, with: GraderPermissionPolicy))
  end
end
