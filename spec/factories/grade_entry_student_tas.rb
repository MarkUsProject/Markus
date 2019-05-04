FactoryBot.define do
  factory :grade_entry_student_ta do
    association :grade_entry_student, factory: :grade_entry_student
    association :ta, factory: :ta
  end
end
