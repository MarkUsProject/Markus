# Policy for annotation categories controller.
class AnnotationCategoryPolicy < ApplicationPolicy
  default_rule :manage?

  def manage?
    user.admin? || (user.ta? && allowed_to?(:manage_assessments?, with: GraderPermissionPolicy))
  end
end
