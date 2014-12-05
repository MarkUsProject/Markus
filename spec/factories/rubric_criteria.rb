FactoryGirl.define do
  factory :rubric_criterion do
    sequence(:rubric_criterion_name) { |n| "Rubric criterion #{n}" }
    association :assignment, factory: :rubric_assignment
    weight 1.0
    level_0_name 'Poor'
    level_0_description 'This criterion was not satisifed whatsoever.'
    level_1_name 'Satisfactory'
    level_1_description 'This criterion was satisfied.'
    level_2_name 'Good'
    level_2_description 'This criterion was satisfied well.'
    level_3_name 'Great'
    level_3_description 'This criterion was satisfied very well.'
    level_4_name 'Excellent'
    level_4_description 'This criterion was satisfied exceptionally well.'
  end
end
