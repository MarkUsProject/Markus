FactoryBot.define do
  factory :peer_review do
    result { association :result, marking_state: 'incomplete', grouping: result_grouping }
    reviewer { create :grouping, assignment: assignment }

    transient do
      assignment { create(:assignment) }
      result_grouping { create(:grouping, assignment: assignment) }
    end
  end
end
