# Marks grader policy class
class MarksGraderPolicy < ApplicationPolicy
  default_rule :manage?

  def manage?
    check?(:manage_assessments?, role)
  end
end
