# Annotation policy class
class AnnotationPolicy < ApplicationPolicy
  def manage?
    role.instructor? || role.ta? || (
        record&.result&.submission&.assignment&.has_peer_review &&
            role.is_reviewer_for?(record&.result&.submission&.assignment&.pr_assignment, record&.result)
      )
  end

  def add_existing_annotation?
    role.instructor? || role.ta?
  end
end
