FactoryBot.define do
  factory :level do
    name { Faker::Lorem.word }
    description { Faker::Lorem.word }
    rubric_criteria
  end
end
