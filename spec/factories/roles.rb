FactoryBot.define do
  factory :role do
    association :human
    association :course
  end
end
