class GroupsChannel < ApplicationCable::Channel
  def subscribed
    stream_for current_user
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def implicit_authorization_target
    assignment
  end

  def authorization_rule
    :manage?
  end
end
