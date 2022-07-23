module Api
  # Policies for Api::Tag Controller
  class TagPolicy < MainApiPolicy
    alias_rule :create?, :update?, :destroy, to: :index

    def index?
      # has at least one instructor role
      role.instructor?
    end
  end
end
