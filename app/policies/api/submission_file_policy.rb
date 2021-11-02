module Api
  # Policies for Api::SubmissionFilesController
  class SubmissionFilePolicy < MainApiPolicy
    def index?
      user.test_server? || check?(:manage?)
    end
  end
end
