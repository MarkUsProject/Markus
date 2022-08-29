module Api
  # Main Api policy class
  class MainApiPolicy < ApplicationPolicy
    default_rule :manage?

    skip_pre_check :role_exists?
    skip_pre_check :view_hidden_course?
    pre_check :admin_user?

    def manage?
      role&.instructor? || false
    end

    def admin_user?
      allow! if real_user.admin_user?
    end
  end
end
