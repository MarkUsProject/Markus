# Policy for annotation categories controller.
class AnnotationCategoryPolicy < ApplicationPolicy
  def manage?
    check?(:manage_assessments?, user)
  end
end
