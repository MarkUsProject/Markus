FactoryBot.define do
  factory :test_batch do
    association :course, factory: :course
  end
end
