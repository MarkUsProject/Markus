FactoryBot.define do
  factory :rubric_criterion do
    sequence(:name) { |n| "Rubric criterion #{n}" }
    association :assignment, factory: :assignment
    max_mark { 4.0 }
    ta_visible { true }
    peer_visible { false }
    sequence(:position)
  end

  factory :rubric_with_levels, parent: :rubric_criterion do
    after(:build) do |criteria| # called by both create and build
      5.times.each { |i|
        create(:level, rubric_criterion: criteria, mark: i)
      }
    end
  end
end
