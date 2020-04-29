FactoryBot.define do
  factory :test_run do
    association :grouping
    association :user, factory: :admin
    revision_identifier { Faker::Number.hexadecimal(digits: 40) }
  end
end
