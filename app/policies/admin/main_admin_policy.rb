module Admin
  # Main Admin policy class
  class MainAdminPolicy < ApplicationPolicy
    default_rule :manage?

    skip_pre_check :role_exists?
    skip_pre_check :view_hidden_course?

    def manage?
      real_user.admin_user?
    end
  end
end
