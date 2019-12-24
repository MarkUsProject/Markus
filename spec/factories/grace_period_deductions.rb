FactoryBot.define do
  factory :grace_period_deduction do
    association :membership
    deduction { 1 }
  end
end
