module Api
  # Main Api policy class
  class MainApiPolicy < ApplicationPolicy
    default_rule :manage?

    def manage?
      user.admin? || user.test_server?
    end
  end
end
