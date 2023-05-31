class TestRunsChannel < ApplicationCable::Channel
  def subscribed
    course = Course.find_by(id: params[:course_id])
    role = Role.find_by(user: current_user, course: course)
    if role.nil?
      reject
      return
    end
    assignment = course&.assignments&.find_by(id: params[:assignment_id])
    grouping = assignment&.groupings&.find_by(id: params[:grouping_id])
    submission = grouping&.submissions&.find_by(id: params[:submission_id])

    unless allowed_to?(:run_tests?, role, context: {
      real_user: current_user,
      role: role,
      assignment: assignment,
      grouping: grouping,
      submission: submission
    })
      reject
      return
    end
    stream_for current_user
  end

  def unsubscribed; end
end
