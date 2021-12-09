module Api
  # Policies for Api::AssignmentsController
  class AssignmentPolicy < MainApiPolicy
    skip_pre_check :role_exists?, only: [:test_files?]
    def test_files?
      real_user.autotest_user? || check?(:manage?)
    end
  end
end
