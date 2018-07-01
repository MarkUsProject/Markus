FactoryBot.define do
  factory :grouping do
    association :group
    association :assignment
  end

  factory :grouping_with_inviter, class: Grouping do
    association :group
    association :assignment
    inviter { FactoryBot.create(:student) }
  end
end
