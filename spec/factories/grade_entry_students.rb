FactoryGirl.define do
  factory :grade_entry_student do
    association :user, :factory => :user2
    user_id 1
    grade_entry_form_id 1
  end
end
