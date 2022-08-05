# Policy for LTI controller
class LtiDeploymentPolicy < ApplicationPolicy
  skip_pre_check :role_exists?

  default_rule :manage?

  def manage?
    !Rails.env.production? # This feature is not ready for production yet
  end
end
