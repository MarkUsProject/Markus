# Policy for annotation categories controller.
class AnnotationCategoryPolicy < ApplicationPolicy
  default_rule :manage?

  def manage?
    check?(:manage_assessments?, user)
  end
end
