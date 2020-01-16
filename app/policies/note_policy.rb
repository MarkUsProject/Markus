class NotePolicy < ApplicationPolicy
  default_rule :manage?

  def manage?
    user.ta? || user.admin?
  end

  def ensure_can_modify?
    user.admin? || user.id == record.creator_id
  end

  def edit?
    check?(:ensure_can_modify?)
  end

  def update?
    check?(:ensure_can_modify?)
  end
end
