FactoryBot.define do
  factory :assessment_section_properties do
    association :assessment
    association :section
    due_date { 1.minute.from_now }
    is_hidden { false }
  end
end
