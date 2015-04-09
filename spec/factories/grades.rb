FactoryGirl.define do
  factory :grade do
    #association :grade_entry_form, factory: :grade_entry_form_with_data
    association :grade_entry_item, factory: :grade_entry_item
    #association :grade_entry_student, factory: :grade_entry_student
    grade 10.0
  end
end
