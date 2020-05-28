FactoryBot.define do
  factory :grader_permissions, class: GraderPermissions do
    association :user, factory: :ta
  end
end
