module Api
  # Policies for Api::AssignmentsController
  class AssignmentPolicy < MainApiPolicy
    skip_pre_check :role_exists?, only: [:test_files?]
    def test_files?
      real_user.test_server? || check?(:manage?)
    end
  end
end
