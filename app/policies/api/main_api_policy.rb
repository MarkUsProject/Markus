module Api
  # Main Api policy class
  class MainApiPolicy < ApplicationPolicy
    default_rule :manage?

    def manage?
      role&.instructor? || false
    end
  end
end
