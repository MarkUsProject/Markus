module Api
  # Policies for Api::Tag Controller
  class TagPolicy < MainApiPolicy
    def index?
      # has at least one instructor role
      real_user.is_a?(EndUser) && real_user.roles.pluck(:type).include?('Instructor')
    end

    def update?
      # has at least one instructor role
      real_user.is_a?(EndUser) && real_user.roles.pluck(:type).include?('Instructor')
    end

    def destroy?
      # has at least one instructor role
      real_user.is_a?(EndUser) && real_user.roles.pluck(:type).include?('Instructor')
    end

    def edit?
      # has at least one instructor role
      real_user.is_a?(EndUser) && real_user.roles.pluck(:type).include?('Instructor')
    end

    def create?
      # has at least one instructor role
      real_user.is_a?(EndUser) && real_user.roles.pluck(:type).include?('Instructor')
    end

    def add_tag?
      # has at least one instructor role
      real_user.is_a?(EndUser) && real_user.roles.pluck(:type).include?('Instructor')
    end

    def remove_tag?
      # has at least one instructor role
      real_user.is_a?(EndUser) && real_user.roles.pluck(:type).include?('Instructor')
    end
  end
end
