FactoryBot.define do
  factory :test_group do
    association :assignment
    name { Faker::Lorem.word }
  end
end
