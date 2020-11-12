# User policy class
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
    true
  end

  # Students and TAs shouldn't be able to change their API key
  def reset_api_key?
    user.admin?
  end
end
