module Api
  # Policies for Api::CoursesController
  class CoursePolicy < MainApiPolicy
    alias_rule :create?, :update?, :update_autotest_url?,
               :test_autotest_connection?, :reset_autotest_connection?, to: :admin_user?

    def index?
      real_user.is_a?(EndUser)
    end
  end
end
