module Api
  # Policies for Api::Tag Controller
  class TagPolicy < MainApiPolicy
    alias_rule :create?, :update?, :destroy, :index, to: manage?

    def manage?
      # is an instructor for the course
      role.instructor?
    end
  end
end
