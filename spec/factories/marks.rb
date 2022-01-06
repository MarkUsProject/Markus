FactoryBot.define do
  factory :mark do
    result do
      create :complete_result, submission: create(:submission, grouping: create(:grouping, assignment: assignment))
    end

    transient do
      assignment { build :assignment }
    end

    factory :rubric_mark do
      criterion { create :rubric_criterion, assignment: assignment }
    end

    factory :flexible_mark do
      criterion { create :flexible_criterion, assignment: assignment }
    end

    factory :checkbox_mark do
      criterion { create :checkbox_criterion, assignment: assignment }
    end
  end
end
