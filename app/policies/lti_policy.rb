# Policy for LTI controller
class LtiPolicy < ApplicationPolicy
  skip_pre_check :role_exists?

  default_rule :manage?

  def manage?
    Role.where(user: real_user, type: 'Instructor').present?
  end
end
