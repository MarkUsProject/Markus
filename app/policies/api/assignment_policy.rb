module Api
  # Policies for Api::AssignmentsController
  class AssignmentPolicy < MainApiPolicy
    def test_files?
      real_user.autotest_user? || check?(:manage?)
    end
  end
end
