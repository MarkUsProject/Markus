FactoryBot.define do

  factory :SubmissionRule, class: SubmissionRule, parent: :assignment do
    assignment
    id
  end

  factory :PenaltyPeriodSubmissionRule, class: PenaltyPeriodSubmissionRule, parent: :SubmissionRule do
    association :SubmissionRule, factory: :SubmissionRule
  end

  factory :GracePeriodSubmissionRule, class: GracePeriodSubmissionRule, parent: :SubmissionRule do
    association :SubmissionRule, factory: :SubmissionRule
  end

end

