FactoryBot.define do
  factory :test_run do
    association :grouping
    association :user, factory: :admin
    revision_identifier { Faker::Number.hexadecimal(digits: 40) }

    factory :student_test_run do
      association :grouping, factory: :grouping_with_inviter
      user { grouping.inviter }
    end
  end
end
