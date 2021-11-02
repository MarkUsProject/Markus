module Api
  class AssignmentPolicy < MainApiPolicy
    def test_files?
      user.test_server? || check?(:manage?)
    end
  end
end
