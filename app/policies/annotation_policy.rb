class AnnotationPolicy < ApplicationPolicy
  def manage?
    user.admin? || user.ta? || (
        record&.result&.submission&.assignment&.has_peer_review &&
            user.is_reviewer_for?(record&.result&.submission&.assignment&.pr_assignment, record&.result)
    )
  end

  def add_existing_annotation?
    user.admin? || user.ta?
  end
end
