class GraderPolicy < ApplicationPolicy
  def manage?
    check?(:manage_assessments?, user)
  end
end
