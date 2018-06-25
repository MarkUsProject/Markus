FactoryBot.define do
  factory :membership do
    association :user
    association :grouping
  end
end
