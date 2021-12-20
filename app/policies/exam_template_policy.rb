# Policy for Exam templates controller.
class ExamTemplatePolicy < ApplicationPolicy
  default_rule :manage?

  def manage?
    check?(:manage_assessments?, role)
  end
end
