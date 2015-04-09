FactoryGirl.define do
  factory :grade_entry_item do
    #sequence(:name) { |i| "Test#{i}" }
    name 'something'
    out_of 10.0
    position 1
  end
end
