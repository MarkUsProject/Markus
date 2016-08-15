FactoryGirl.define do
  factory :rubric_criterion do
    sequence(:name) { |n| "Rubric criterion #{n}" }
    association :assignment, factory: :assignment
    max_mark 4.0
    ta_visible true
    peer_visible false
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
