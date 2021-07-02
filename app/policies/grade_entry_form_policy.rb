# Policy for Grade entry forms controller
class GradeEntryFormPolicy < ApplicationPolicy
  default_rule :manage?
  alias_rule :grades?, :view_summary?, :update_grade?, :get_mark_columns?,
             :populate_grades_table?, :download?, :upload?, to: :grade?

  def grade?
    user.admin? || user.ta?
  end

  def manage?
    check?(:manage_assessments?, user)
  end

  def student_interface?
    user.student?
  end

  def grade_distribution_data?
    user.admin?
  end
end
