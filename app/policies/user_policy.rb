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

  # Only users that are admins in at least one course
  def reset_api_key?
    user.roles.pluck(:type).include?('Admin')
  end
end
