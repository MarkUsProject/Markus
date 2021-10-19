FactoryBot.define do
  factory :role, class: Role do
    association :user, factory: :user
    association :course, factory: :course
  end
end
