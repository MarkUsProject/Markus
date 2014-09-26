FactoryGirl.define do
  factory :mark do
  	association :result, factory: :result, marking_state: 'complete'
  	association :markable, factory: :rubric_criterion
  end
end