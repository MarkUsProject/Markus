module Api
  # Policies for Api::SubmissionFilesController
  class SubmissionFilePolicy < MainApiPolicy
    def index?
      real_user.autotest_user? || check?(:manage?)
    end
  end
end
