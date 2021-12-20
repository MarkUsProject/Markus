FactoryBot.define do
  factory :grouping do
    association :group, strategy: :build
    association :assignment, strategy: :build
    start_time { nil }

    before(:create) do |grouping|
      grouping.group.course = grouping.assignment.course if grouping.group.new_record?
      grouping.assignment.course = grouping.group.course if grouping.assignment.new_record?
    end

    factory :grouping_with_inviter do
      transient do
        inviter { build(:student) }
      end

      after(:create) do |grouping, evaluator|
        evaluator.inviter.course = grouping.course unless evaluator.inviter.persisted?
        create :inviter_student_membership, grouping: grouping, role: evaluator.inviter
        evaluator.inviter.save!
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
