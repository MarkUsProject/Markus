FactoryBot.define do
  factory :peer_review do
    result { association :result, marking_state: 'incomplete', submission: result_grouping.current_submission_used }
    reviewer { association :grouping, assignment: assignment.pr_assignment }

    transient do
      assignment { association :assignment_with_peer_review }
      result_grouping { association :grouping_with_inviter_and_submission, assignment: assignment }
    end
  end
end
