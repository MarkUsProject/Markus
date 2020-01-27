class NotePolicy < ApplicationPolicy
  default_rule :manage?
  alias_rule :edit?, :update?, to: :modify?

  def manage?
    user.ta? || user.admin?
  end

  def modify?
    user.admin? || user.id == record.creator_id
  end
end
