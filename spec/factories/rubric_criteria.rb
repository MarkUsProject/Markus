FactoryBot.define do
  factory :rubric_criterion do
    sequence(:name) { |n| "Rubric criterion #{n}" }
    association :assignment
    max_mark { 4.0 }
    ta_visible { true }
    peer_visible { false }
    sequence(:position)
    after(:build) do |criterion|
      5.times.each do |i|
        criterion.levels << build(:level, criterion: criterion, mark: criterion.max_mark * i / 4)
      end
    end
  end
end
