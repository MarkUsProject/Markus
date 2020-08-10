FactoryBot.define do
  factory :period do
    association :submission_rule, factory: :penalty_period_submission_rule
    deduction { 1 }
    hours { 1 }
    interval { 1 }
  end
end
