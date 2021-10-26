FactoryBot.define do
  factory :role do
    association :human, factory: :human
    association :course
  end
end
