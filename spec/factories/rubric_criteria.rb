FactoryBot.define do
  factory :rubric_criterion do
    sequence(:name) { |n| "Rubric criterion #{n}" }
    association :assignment, factory: :assignment
    max_mark { 4.0 }
    ta_visible { true }
    peer_visible { false }
    sequence(:position)
  end

  factory :rubric_criteria_with_levels do
    after(:create) do |criteria|
      5.times.each { |i| create(:level, rubric_criteria: rubric_criteria, mark: i) }
    end
  end
end
