class StudentTestsChannel < ApplicationCable::Channel
  def subscribed
    course = Course.find_by(id: params[:course_id])
    role = Role.find_by(user: current_user, course: course)
    assignment = Assignment.find_by(id: params[:assignment_id])
    grouping = Grouping.find_by(id: params[:grouping_id])
    submission = Submission.find_by(id: params[:submission_id])
    if role.nil?
      reject
    end
    # Execute test run only checks if the user is a student, so checking run_tests? only ever calls the method in
    # StudentPolicy
    unless allowed_to?(:execute_test_run?,
                       with: AutomatedTestPolicy,
                       context: { real_user: current_user, role: role }) && allowed_to?(:run_tests?,
                                                                                        role,
                                                                                        context: {
                                                                                          real_user: current_user,
                                                                                          role: role,
                                                                                          assignment: assignment,
                                                                                          grouping: grouping,
                                                                                          submission: submission
                                                                                        })
      reject
    end
    stream_for current_user
  end

  def unsubscribed; end
end
