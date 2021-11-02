module Api
  class SubmissionFilePolicy < MainApiPolicy
    def index?
      user.test_server? || check?(:manage?)
    end
  end
end
