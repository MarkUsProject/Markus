FactoryBot.define do
  factory :grader_permission, class: 'GraderPermission' do
    association :ta
  end
end
