FactoryBot.define do
  factory :groupings_tags do
    association :grouping
    association :tag
  end
end
