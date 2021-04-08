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

    factory :remark_result do
      marking_state { Result::MARKING_STATES[:incomplete] }
      remark_request_submitted_at { Time.current }
    end
  end
end
