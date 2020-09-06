# Policy for Exam templates controller.
class ExamTemplatePolicy < ApplicationPolicy
  default_rule :manage?

  # Only admin and authorized grader can manage or modify exam templates
  def manage?
    allowed_to?(:manage_assessments?, with: GraderPermissionPolicy)
  end
end
