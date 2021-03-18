FactoryBot.define do
  factory :grouping_starter_file_entry do
    transient do
      assignment { build :assignment }
      starter_file_group { build :starter_file_group, assignment: assignment }
    end
    before :create do |gsfe, evaluator|
      gsfe.grouping = create(:grouping, assignment: evaluator.starter_file_group.assignment)
      gsfe.starter_file_entry = create(:starter_file_entry, starter_file_group: evaluator.starter_file_group)
    end
  end
end
