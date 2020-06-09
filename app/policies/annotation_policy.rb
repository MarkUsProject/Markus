class AnnotationPolicy < ApplicationPolicy
  default_rule :manage?
  def add_existing_annotation?
    user.admin? || (user.ta? && check?(:is_ta_allowed?))
  end

  def manage?
    user.admin? || (user.ta? && check?(:is_ta_allowed?)) || (authorized?(user) && check?(:is_reviewer_allowed?))
  end

  def is_ta_allowed?
    allowed_to?(:create_delete_annotations?, with: GraderPermissionPolicy)
  end

  def is_reviewer_allowed?
    assignment = result.submission.assignment
    assignment.has_peer_review && user.is_reviewer_for?(assignment.pr_assignment, result)
  end
end
