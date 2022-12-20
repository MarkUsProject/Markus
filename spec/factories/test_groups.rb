FactoryBot.define do
  factory :test_group do
    association :assignment
    sequence(:name) { |n| "Test Group #{n}" }
    sequence(:position) { |n| n }
  end
end
