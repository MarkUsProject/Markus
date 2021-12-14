module Api
  # Policies for Api::UserPolicy
  class UserPolicy < MainApiPolicy
    def manage?
      false
    end
  end
end
