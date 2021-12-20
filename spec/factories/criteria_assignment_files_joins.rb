FactoryBot.define do
  factory :criteria_assignment_files_join do
    association :criterion, factory: :rubric_criterion
    association :assignment_file
  end
end
