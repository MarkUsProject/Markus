class StudentTestsChannel < ApplicationCable::Channel
  def subscribed
    # course = Course.find_by(id: params[:course_id])
    # role = Role.find_by(user: current_user, course: course)
    # assignment = Assignment.find_by(id: params[:assignment_id])
    # grouping = Grouping.find_by(id: params[:grouping_id])
    # if role.nil? || assignment.nil? || grouping.nil?
    #   reject
    # end
    # unless allowed_to?(:run_tests?,
    #                    current_role,
    #                    context: { assignment: params[:assignment_id], grouping: params[:grouping_id] })
    #   reject
    # end
    stream_for current_user
  end

  def unsubscribed; end
end
