class UpdateResultsMarkingStatesJob < ApplicationJob
  def perform(assignment_id, marking_state)
    Result.includes(submission: :grouping)
          .where(groupings: { assessment_id: assignment_id })
          .update!(marking_state: Result::MARKING_STATES[marking_state])
  end
end
