# Policy for Exam templates controller.
class ExamTemplatePolicy < ApplicationPolicy
  default_rule :manage?

  def add_fields?
    Settings.scanned_exams.enabled && check?(:manage?)
  end

  def manage?
    check?(:manage_assessments?, role)
  end
end
