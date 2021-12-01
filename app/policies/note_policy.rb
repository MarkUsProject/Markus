# Note policy class
class NotePolicy < ApplicationPolicy
  default_rule :manage?
  alias_rule :edit?, :update?, to: :modify?

  def manage?
    role.ta? || role.admin?
  end

  def modify?
    role.admin? || role.id == record.creator_id
  end
end
