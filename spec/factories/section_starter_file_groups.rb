FactoryBot.define do
  factory :section_starter_file_group do
    association :section
    association :starter_file_group
  end
end
