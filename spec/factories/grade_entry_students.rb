FactoryGirl.define do
  factory :grade_entry_student do
    association :user, factory: :user
  end
end
