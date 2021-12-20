FactoryBot.define do
  factory :membership do
    association :role
    association :grouping
  end
end
