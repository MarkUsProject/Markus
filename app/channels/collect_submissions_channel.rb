class CollectSubmissionsChannel < ApplicationCable::Channel
  def subscribed
    unless allowed_to?(:collect_submissions?, with: SubmissionPolicy, context: { real_user: current_user,
                                                                                 role: current_user,
                                                                                 real_role: current_user })
      reject
    end
    stream_for current_user
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
