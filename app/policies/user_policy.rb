class UserPolicy < ApplicationPolicy
  # Default rule: only admins can manage users.
  def manage?
    user.admin?
  end

  # No one can delete users.
  def destroy?
    false
  end

  def mailer_settings?
    user.is_a?(Student)
  end

  def update_mailer_settings?
    user.is_a?(Student)
  end
end
