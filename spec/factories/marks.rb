FactoryBot.define do
  factory :mark do
    association :result, factory: :complete_result

    factory :rubric_mark do
      association :markable, factory: :rubric_criterion
      markable_type { 'RubricCriterion' }
    end

    factory :flexible_mark do
      association :markable, factory: :flexible_criterion
      markable_type { 'FlexibleCriterion' }
    end
  end
end
