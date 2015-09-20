FactoryGirl.define do
  factory :ta_membership, class: TaMembership, parent: :membership do
    association :user, factory: :ta
  end
end
