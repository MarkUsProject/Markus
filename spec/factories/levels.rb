FactoryBot.define do
  factory :level do
    association :rubric_criteria
    name { Faker::Lorem.word }
    description { Faker::Lorem.word }
    mark
  end
end
