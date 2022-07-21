module Api
  # Policies for Api::Tag Controller
  class TagPolicy < MainApiPolicy
    alias_rule :create?, :update?, :destroy, to: :index
    def index?
      # has at least one instructor role
      real_user.is_a?(EndUser) && real_user.roles.pluck(:type).include?('Instructor')
    end
  end
end
