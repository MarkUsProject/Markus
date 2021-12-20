# Grader policy class
class GraderPolicy < ApplicationPolicy
  def manage?
    check?(:manage_assessments?, role)
  end
end
