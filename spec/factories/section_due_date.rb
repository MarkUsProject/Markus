FactoryBot.define do

  factory :section_due_date do
    assignment
    section
    due_date { 1.minute.from_now }
  end

end
