module Api
  # Policies for Api::CoursesController
  class CoursePolicy < MainApiPolicy
    alias_rule :create?, :update?, :update_autotest_url?,
               :test_autotest_connection?, :reset_autotest_connection?, to: :admin_user?

    def index?
      # has at least one instructor role
      real_user.is_a?(EndUser) && real_user.roles.exists?
    end
  end
end
