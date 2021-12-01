# Annotation policy class
class AnnotationPolicy < ApplicationPolicy
  def manage?
    role.admin? || role.ta? || (
        record&.result&.submission&.assignment&.has_peer_review &&
            role.is_reviewer_for?(record&.result&.submission&.assignment&.pr_assignment, record&.result)
    )
  end

  def add_existing_annotation?
    role.admin? || role.ta?
  end
end
