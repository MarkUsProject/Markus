FactoryGirl.define do
  factory :grade_entry_item do
    name 'something'
    out_of 10.0
    position 1
  end
  
  factory :another_grade_entry_item, class: GradeEntryItem do
    name 'not_something'
    out_of 10.0
    position 2
  end
end
