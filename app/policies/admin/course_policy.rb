module Admin
  # Policies for Admin::CoursesController
  class CoursePolicy < ApplicationPolicy
    default_rule :manage?

    skip_pre_check :role_exists?
    pre_check :admin_user?

    def manage?
      real_user.admin_user?
    end

    def edit?
      real_user.admin_user?
    end
  end
end
