FactoryGirl.define do
  factory :mark do
    association :result, factory: :result, marking_state: 'complete'

    factory :rubric_mark do
      association :markable, factory: :rubric_criterion
    end

    factory :flexible_mark do
      association :markable, factory: :flexible_criterion
    end
  end
end
