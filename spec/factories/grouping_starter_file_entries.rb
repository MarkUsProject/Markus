FactoryBot.define do
  factory :grouping_starter_file_entry do
    transient do
      assignment { association :assignment, strategy: :build }
      starter_file_group { association :starter_file_group, assignment: assignment, strategy: :build }
      grouping { nil }
      starter_file_entry { nil }
    end
    before :create do |gsfe, evaluator|
      gsfe.grouping = evaluator.grouping || create(:grouping, assignment: evaluator.starter_file_group.assignment)
      gsfe.starter_file_entry = evaluator.starter_file_entry || create(:starter_file_entry,
                                                                       starter_file_group: evaluator.starter_file_group)
    end
  end
end
