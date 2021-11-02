module Api
  class CoursePolicy < MainApiPolicy
    def index?
      # has at least one admin role
      user.is_a?(Human) && user.roles.pluck(:type).include?('Admin')
    end
  end
end
