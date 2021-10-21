FactoryBot.define do
  factory :grade_entry_student do
    association :role, factory: :student
  end
end
