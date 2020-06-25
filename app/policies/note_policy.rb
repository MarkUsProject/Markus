class NotePolicy < ApplicationPolicy
  default_rule :manage?
  alias_rule :edit?, :update?, to: :modify?
  alias_rule :new?, :create, to: :new_note?

  def manage?
    user.ta? || user.admin?
  end

  def modify?
    user.admin? || user.id == record.creator_id
  end

  def new_note?
    user.admin? || (user.ta? && allowed_to?(:create_notes?, with: GraderPermissionPolicy))
  end
end
