class TestRunsChannel < ApplicationCable::Channel
  authorize :assignment, through: :assignment
  authorize :grouping, through: :grouping
  authorize :submission, through: :submission

  def subscribed
    stream_for current_user
  end

  private

  def implicit_authorization_target
    current_role
  end

  def authorization_rule
    :run_tests?
  end

  def assignment
    course&.assignments&.find_by(id: params[:assignment_id])
  end

  def grouping
    assignment&.groupings&.find_by(id: params[:grouping_id])
  end

  def submission
    grouping&.submissions&.find_by(id: params[:submission_id])
  end

  def unsubscribed; end
end
