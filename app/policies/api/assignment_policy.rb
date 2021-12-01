module Api
  # Policies for Api::AssignmentsController
  class AssignmentPolicy < MainApiPolicy
    def test_files?
      real_user.test_server? || check?(:manage?)
    end
  end
end
