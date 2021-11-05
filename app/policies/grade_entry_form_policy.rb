# Policy for Grade entry forms controller
class GradeEntryFormPolicy < ApplicationPolicy
  default_rule :manage?
  alias_rule :grades?, :update_grade?, :get_mark_columns?,
             :populate_grades_table?, :download?, :upload?, to: :grade?

  def switch?
    true
  end

  def grade?
    role.admin? || role.ta?
  end

  def manage?
    check?(:manage_assessments?, role)
  end

  def see_hidden?
    role.admin? || role.ta? || role.visible_assessments(assessment_id: record.id).exists?
  end

  def student_interface?
    role.student?
  end
end
