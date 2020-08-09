FactoryBot.define do
  factory :grouping_starter_file_entry do
    association :grouping
    association :starter_file_entry
  end
end
