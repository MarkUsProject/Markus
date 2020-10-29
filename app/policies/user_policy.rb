class UserPolicy < ApplicationPolicy
  # Default rule: only admins can manage users.
  def manage?
    user.admin?
  end

  # No one can delete users.
  def destroy?
    false
  end

  def settings?
    true
  end

  def update_settings?
    user.student?
  end
end
