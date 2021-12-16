module Api
  # Policies for Api::CoursesController
  class CoursePolicy < MainApiPolicy

    def index?
      # has at least one instructor role
      real_user.is_a?(EndUser) && real_user.roles.pluck(:type).include?('Instructor')
    end

    def create?
      real_user.admin_user?
    end

    def update_autotest_url?
      real_user.admin_user?
    end

    def update?
      real_user.admin_user?
    end
  end
end
