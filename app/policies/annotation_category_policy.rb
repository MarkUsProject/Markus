# Policy for annotation categories controller.
class AnnotationCategoryPolicy < ApplicationPolicy
  default_rule :manage?

  def manage?
    user.admin? ||
        (user.ta? && check?(:grader_allowed?) && allowed_to?(:manage_assessments?, with: GraderPermissionPolicy))
  end

  def grader_allowed?
    allowed_to?(:create_delete_annotations?, with: GraderPermissionPolicy)
  end
end
