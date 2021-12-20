FactoryBot.define do
  factory :test_run do
    association :grouping
    association :role, factory: :instructor
    revision_identifier { Faker::Number.hexadecimal(digits: 40) }
    status { :complete }
    factory :student_test_run do
      association :grouping, factory: :grouping_with_inviter
      role { grouping.inviter }
    end
  end
end
