FactoryGirl.define do
  factory :grade_entry_student do
    association :user, factory: :user_UTF_8
    after(:create) do |grade_entry_student|
      create(:grade, grade_entry_student: grade_entry_student)
    end
  end
end
