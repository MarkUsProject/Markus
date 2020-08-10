FactoryBot.define do
  factory :mark do
    association :result, factory: :complete_result

    factory :rubric_mark do
      association :criterion, factory: :rubric_criterion
    end

    factory :flexible_mark do
      association :criterion, factory: :flexible_criterion
    end

    factory :checkbox_mark do
      association :criterion, factory: :checkbox_criterion
    end
  end
end
