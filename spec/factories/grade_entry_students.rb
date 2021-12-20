FactoryBot.define do
  factory :grade_entry_student do
    association :role, factory: :student
    association :grade_entry_form
  end
end
