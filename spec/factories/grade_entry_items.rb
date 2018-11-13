FactoryBot.define do
  factory :grade_entry_item do
    sequence(:name) { |i| "Test#{i}" }
    out_of { 100.0 }
    position { 1 }
    grade_entry_form
  end
end
