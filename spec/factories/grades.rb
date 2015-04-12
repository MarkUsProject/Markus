FactoryGirl.define do
  factory :grade do
    association :grade_entry_item, factory: :grade_entry_item
    grade 8.0
  end

  factory :another_grade, class: Grade do
    association :grade_entry_item, factory: :another_grade_entry_item
    grade 10.0
  end
end
