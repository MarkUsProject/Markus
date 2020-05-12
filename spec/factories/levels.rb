FactoryBot.define do
  factory :level do
    association :criterion, factory: :rubric_criterion
    sequence(:name) { |i| "Level #{i}" }
    description { Faker::Lorem.word }
  end
end
