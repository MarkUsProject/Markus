FactoryBot.define do
  factory :grade_entry_student do
    association :user, factory: :student
  end
end
