module Api
  # Policies for Api::CoursesController
  class CoursePolicy < MainApiPolicy
    def index?
      # has at least one admin role
      real_user.is_a?(Human) && real_user.roles.pluck(:type).include?('Admin')
    end
  end
end
