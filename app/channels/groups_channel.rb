class GroupsChannel < ApplicationCable::Channel
  def subscribed
    course = Course.find_by(id: params[:course_id])
    assignment = course&.assignments&.find_by(id: params[:assignment_id])
    role = Role.find_by(user: current_user, course: course)
    if assignment.nil? || role.nil?
      reject
      return
    end
    unless allowed_to?(:manage?, assignment, context: { real_user: current_user, role: role })
      reject
      return
    end
    stream_for current_user
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
