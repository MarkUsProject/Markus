FactoryGirl.define do
  factory :student_membership, class: StudentMembership, parent: :membership do
    association :user, factory: :student

    factory :inviter_student_membership do
      membership_status StudentMembership::STATUSES[:inviter]
    end

    factory :accepted_student_membership do
      membership_status StudentMembership::STATUSES[:accepted]
    end
  end
end
