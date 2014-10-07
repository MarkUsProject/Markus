FactoryGirl.define do
  factory :rubric_criterion do
    sequence(:rubric_criterion_name) { |n| "Rubric criterion #{n}" }
    association :assignment, factory: :rubric_assignment
    weight 1.0
  end
end
