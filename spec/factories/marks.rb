FactoryBot.define do
  factory :mark do
    association :result, factory: :complete_result

    factory :rubric_mark do
      criterion { association :rubric_criterion, assignment: result.submission.grouping.assignment }
    end

    factory :flexible_mark do
      criterion { association :flexible_criterion, assignment: result.submission.grouping.assignment }
    end

    factory :checkbox_mark do
      criterion { association :checkbox_criterion, assignment: result.submission.grouping.assignment }
    end
  end
end
