FactoryBot.define do
  factory :level do
    sequence(:name) { |i| "Level #{i}" }
    description { Faker::Lorem.word }
    rubric_criterion
  end
end
