module Api
  # Policies for Api::AssignmentsController
  class AssignmentPolicy < MainApiPolicy
    def test_files?
      real_user.autotest_user? || check?(:manage?)
    end

    def submit_file?
      role&.student? && check?(:see_hidden?)
    end
  end
end
