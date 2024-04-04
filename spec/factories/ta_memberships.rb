FactoryBot.define do
  factory :ta_membership, class: 'TaMembership', parent: :membership do
    association :role, factory: :ta
  end
end
