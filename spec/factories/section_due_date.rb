FactoryBot.define do

  factory :section_due_date do
    association :assessment
    association :section
    due_date { 1.minute.from_now }
    is_hidden { false }
  end

end
