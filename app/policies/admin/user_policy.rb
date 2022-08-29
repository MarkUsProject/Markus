module Admin
  # Policies for Admin::UsersController
  class UserPolicy < ApplicationPolicy
    default_rule :manage?

    skip_pre_check :role_exists?
    skip_pre_check :view_hidden_course?
    pre_check :admin_user?

    def manage?
      real_user.admin_user?
    end
  end
end
