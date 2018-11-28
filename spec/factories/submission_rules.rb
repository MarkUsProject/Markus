FactoryBot.define do

  factory :submission_rule, class: SubmissionRule do
    assignment
  end

  factory :penalty_period_submission_rule, parent: :submission_rule do
  end

  factory :grace_period_submission_rule, parent: :submission_rule do
  end

end
