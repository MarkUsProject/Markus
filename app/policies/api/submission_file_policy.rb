module Api
  # Policies for Api::SubmissionFilesController
  class SubmissionFilePolicy < MainApiPolicy
    skip_pre_check :role_exists?, only: [:index?]
    def index?
      real_user.test_server? || check?(:manage?)
    end
  end
end
