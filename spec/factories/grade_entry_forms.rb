FactoryGirl.define do
  factory :grade_entry_form do
    sequence(:short_identifier) { |i| "Spreadsheet#{i}" }
    date { Time.now }
  end
end
