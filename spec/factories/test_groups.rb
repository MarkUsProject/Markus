FactoryBot.define do
  factory :test_group do
    association :assignment
    name { Faker::Lorem.word }
    display_output { 'instructors_only' }
    run_by_instructors { false }
    run_by_students { false }
  end
end
