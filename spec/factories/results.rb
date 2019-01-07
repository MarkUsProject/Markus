FactoryBot.define do
  factory :result do
    association :submission

    factory :incomplete_result do
      marking_state { Result::MARKING_STATES[:incomplete] }
    end

    factory :complete_result do
      marking_state { Result::MARKING_STATES[:complete] }

      factory :released_result do
        released_to_students { true }
      end
    end
  end
end
