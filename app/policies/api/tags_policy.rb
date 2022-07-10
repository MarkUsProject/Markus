module Api
  # Policies for Api::AssignmentsController
  class TagPolicy < MainApiPolicy
    alias_rule :create?, :update?, :update_autotest_url?, to: :admin_user?

    def index?
      # has at least one instructor role
      real_user.is_a?(EndUser) && real_user.roles.pluck(:type).include?('Instructor')
    end
  end
end
