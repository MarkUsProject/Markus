FactoryBot.define do
  factory :grouping do
    association :group
    association :assignment

    factory :grouping_with_inviter do
      transient do
        inviter { create(:student) }
      end

      after(:create) do |grouping, evaluator|
        create :inviter_student_membership, grouping: grouping, user: evaluator.inviter
        grouping.reload
      end
    end
  end

  factory :grouping_with_inviter_and_submission, parent: :grouping_with_inviter do
    after(:create) do |g|
      create(:version_used_submission, grouping: g)
      g.reload
    end
  end
end
