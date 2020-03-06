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

  factory :grouping_with_inviter_and_submission, parent: :grouping_with_inviter do
    after(:create) do |g|
      create(:incomplete_result, submission: create(:version_used_submission, grouping: g))
    end
  end
end
