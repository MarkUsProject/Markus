FactoryBot.define do

  factory :section_due_date do
    association :assignment
    association :section
    due_date { 1.minute.from_now }
  end

end
