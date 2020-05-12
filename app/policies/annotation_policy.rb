class AnnotationPolicy < ApplicationPolicy
  alias_rule  :destroy?, :edit?, :update?, to: :manage?
  alias_rule :create?, :new?, to: :new_annotation?

  def manage?
    user.admin? || (user.ta? && GraderPermission.find_by(user_id: user.id).create_delete_annotations && (user.id == record.creator_id))
  end

  def add_existing_annotation?
    user.admin? || (user.ta? && GraderPermission.find_by(user_id: user.id).create_delete_annotations)
  end

  def new_annotation?
    user.admin? || user.ta? && GraderPermission.find_by(user_id: user.id).create_delete_annotations
  end
end
