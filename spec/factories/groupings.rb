FactoryGirl.define do
  factory :grouping do
    association :group
    association :assignment
  end
end
