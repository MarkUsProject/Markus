class AnnotationPolicy < ApplicationPolicy
  def add_existing_annotation?
    user.admin? || (user.ta? && allowed_to?(:create_delete_annotations?, with: GraderPermissionPolicy))
  end
end
