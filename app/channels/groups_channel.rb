class GroupsChannel < ApplicationCable::Channel
  authorize :assignment, through: :assignment
  def subscribed
    stream_for current_user
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  private

  def authorize_channel
    reject && return if assignment.nil?
    super
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
