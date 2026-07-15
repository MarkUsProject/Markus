class GroupsChannel < ApplicationCable::Channel
  authorize :assignment, through: :assignment
  def subscribed
    stream_for current_user
  end

  private

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def implicit_authorization_target
    assignment
  end

  def authorization_rule
    :manage?
  end

  def assignment
    course&.assignments&.find_by(id: params[:assignment_id])
  end
end
