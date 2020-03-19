FactoryBot.define do
  factory :grade do
    association :grade_entry_student
    association :grade_entry_item
    grade { 1 }
  end
end
