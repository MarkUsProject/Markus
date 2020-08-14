# Policy for annotation categories controller.
class AnnotationCategoryPolicy < ApplicationPolicy
  default_rule :manage?

  def manage?
    allowed_to?(:manage_assessments?, with: GraderPermissionPolicy)
  end
end
