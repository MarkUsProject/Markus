FactoryGirl.define do
  factory :rubric_criterion do
    sequence(:rubric_criterion_name) { |n| "Rubric criterion #{n}" }
    association :assignment,
                marking_scheme_type: Assignment::MARKING_SCHEME_TYPE[:rubric]
    weight 1.0
  end
end
