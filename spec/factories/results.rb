FactoryGirl.define do
  factory :result do
    association :submission

    factory :unmarked_result do
      marking_state Result::MARKING_STATES[:unmarked]
    end

    factory :partial_result do
      marking_state Result::MARKING_STATES[:partial]
    end

    factory :complete_result do
      marking_state Result::MARKING_STATES[:complete]
    end
  end
end
