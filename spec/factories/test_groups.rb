FactoryBot.define do
  factory :test_group do
    association :assignment
    name { Faker::Lorem.word }
    display_output { TestGroup::TO_INSTRUCTORS }
    run_by_instructors { false }
    run_by_students { false }
  end
end
