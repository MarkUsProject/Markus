class ExamTemplatesChannel < ApplicationCable::Channel
  def subscribed
    stream_for current_user
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def authorization_policy
    SubmissionPolicy
  end

  def authorization_rule
    :update_submissions?
  end
end
