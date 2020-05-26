class NotePolicy < ApplicationPolicy
  default_rule :manage?
  alias_rule :edit?, :update?, to: :modify?

  def manage?
    user.ta? || user.admin?
  end

  def modify?
    user.admin? || user.id == record.creator_id
  end

  def create?
    user.admin? || (user.ta? && allowed_to?(:create_notes?, with: GraderPermissionsPolicy))
  end
end
