FactoryBot.define do
  factory :criterion_ta_association do
    association :criterion, factory: :rubric_criterion
    association :ta
  end
end
