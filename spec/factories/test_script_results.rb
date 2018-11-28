FactoryBot.define do
  factory :test_script_result do
    association :test_script # not mandatory, but only for an edge case where scripts are deleted while testing
    association :test_run
    marks_earned { 1 }
    marks_total { 1 }
    time { Faker::Number.number(4) }
  end
end
