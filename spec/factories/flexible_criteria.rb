FactoryGirl.define do
  factory :flexible_criterion do
    sequence(:flexible_criterion_name) { |n| "Flexible criterion #{n}" }
    association :assignment,
                marking_scheme_type: Assignment::MARKING_SCHEME_TYPE[:flexible]
    max 1.0
  end
end

