class AnnotationPolicy < ApplicationPolicy
  default_rule :manage?
  def add_existing_annotation?
    user.admin? || user.ta?
  end

  def manage?
    user.admin? || (user.ta? && check?(:ta_allowed?)) || ((user.student?) && check?(:reviewer_allowed?))
  end

  def ta_allowed?
    allowed_to?(:create_delete_annotations?, with: GraderPermissionPolicy)
  end

  def reviewer_allowed?
    assignment = record.submission.assignment
    assignment.has_peer_review && user.is_reviewer_for?(assignment.pr_assignment, record)
  end
end
