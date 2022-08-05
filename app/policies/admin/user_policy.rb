module Admin
  # Policies for Admin::UsersController
  class UserPolicy < ApplicationPolicy
    default_rule :manage?

    skip_pre_check :role_exists?
    pre_check :admin_user?

    def manage?
      real_user.admin_user?
    end
  end
end
