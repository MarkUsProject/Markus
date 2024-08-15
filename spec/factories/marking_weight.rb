FactoryBot.define do
  factory :marking_weight do
    association :marking_scheme
    weight { rand(1..10) }
    association :assessment, factory: :assignment
  end
end
