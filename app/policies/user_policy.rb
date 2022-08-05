# User policy class
class UserPolicy < ApplicationPolicy
  skip_pre_check :role_exists?

  def manage?
    false
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

  # Any standard user can reset their API key
  def reset_api_key?
    user.end_user?
  end
end
