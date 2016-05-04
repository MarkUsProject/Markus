FactoryGirl.define do
  factory :flexible_criterion do
    sequence(:name) { |n| "Flexible criterion #{n}" }
    association :assignment, factory: :flexible_assignment
    max 1.0
  end
end

