FactoryBot.define do
  factory :extension do
    association :grouping
    time_delta { rand(1..10).weeks + rand(1..10).days + rand(1..10).hours }
  end
end
