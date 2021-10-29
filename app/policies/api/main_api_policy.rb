module Api
  # Main Api policy class
  class MainApiPolicy < ApplicationPolicy
    default_rule :manage?

    def manage?
      user.test_server? || role&.admin?
    end
  end
end
