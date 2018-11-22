FactoryBot.define do
  factory :test_run do
    association :grouping
    association :user
    revision_identifier { Faker::Number.hexadecimal(40) }
  end
end
