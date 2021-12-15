# Note policy class
class NotePolicy < ApplicationPolicy
  default_rule :manage?
  alias_rule :edit?, :update?, to: :modify?

  def manage?
    role.ta? || role.instructor?
  end

  def modify?
    role.instructor? || role.id == record.creator_id
  end
end
