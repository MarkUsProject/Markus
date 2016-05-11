FactoryGirl.define do
  factory :result do
    association :submission

    factory :incomplete_result do
      marking_state Result::MARKING_STATES[:incomplete]
    end

    factory :complete_result do
      marking_state Result::MARKING_STATES[:complete]
    end
  end
end
