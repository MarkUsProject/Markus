FactoryBot.define do
  factory :rubric_criterion do
    sequence(:name) { |n| "Rubric criterion #{n}" }
    association :assignment, factory: :assignment
    max_mark { 4.0 }
    ta_visible { true }
    peer_visible { false }
    sequence(:position)
    after(:create) do |criterion|
      5.times.each { |i| create(:level, rubric_criteria: criterion, mark: i) }
    end
  end
end
