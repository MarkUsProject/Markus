FactoryBot.define do
  factory :peer_review do
    result { association :result, marking_state: 'incomplete', grouping: result_grouping }
    reviewer { create :grouping, assignment: assignment.pr_assignment }

    transient do
      assignment { create(:assignment_with_peer_review) }
      result_grouping { create(:grouping, assignment: assignment) }
    end
  end
end
