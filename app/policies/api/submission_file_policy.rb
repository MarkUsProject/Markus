module Api
  # Policies for Api::SubmissionFilesController
  class SubmissionFilePolicy < MainApiPolicy
    def index?
      real_user.test_server? || check?(:manage?)
    end
  end
end
