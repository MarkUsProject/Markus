FactoryGirl.define do
  factory :grace_period_deduction, class: GracePeriodDeduction do
    membership { FactoryGirl.create(:student_membership) }
    deduction 20
  end
end
