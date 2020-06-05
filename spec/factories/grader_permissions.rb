FactoryBot.define do
  factory :grader_permission, class: GraderPermission do
    association :user, factory: :ta
  end
end
