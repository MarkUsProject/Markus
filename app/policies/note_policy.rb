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
    user.admin? || (user.ta? && GraderPermission.find_by(user_id: user.id).create_notes)
  end
end
