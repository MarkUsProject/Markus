FactoryBot.define do
  factory :grader_permission, class: GraderPermission do
    association :ta, factory: :ta
  end
end
