FactoryBot.define do

  factory :submission_rule, class: SubmissionRule do
    transient do
      assignment { build(:assignment) }
    end
    after(:build) do |rule, evaluator|
      evaluator.assignment.submission_rule = rule
    end
    after(:create) do |rule|
      rule.assignment.save
    end
  end

  factory :penalty_period_submission_rule, parent: :submission_rule, class: PenaltyPeriodSubmissionRule do
  end

  factory :grace_period_submission_rule, parent: :submission_rule, class: GracePeriodSubmissionRule do
  end

  factory :penalty_decay_period_submission_rule, parent: :submission_rule, class: PenaltyDecayPeriodSubmissionRule do
  end

  factory :no_late_submission_rule, parent: :submission_rule, class: NoLateSubmissionRule do
  end
end
