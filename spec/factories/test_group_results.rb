FactoryBot.define do
  factory :test_group_result do
    association :test_group # not mandatory, but only for an edge case where scripts are deleted while testing
    association :test_run
    marks_earned { 1 }
    marks_total { 1 }
    time { Faker::Number.number(digits: 4) }
    error_type { nil }
  end
end
