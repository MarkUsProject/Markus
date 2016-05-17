FactoryGirl.define do
  factory :peer_review do
    association :result, factory: :result, marking_state: 'incomplete'
    association :reviewer, factory: :grouping
  end
end
