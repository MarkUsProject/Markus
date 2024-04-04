FactoryBot.define do
  factory :checkbox_criterion do
    sequence(:name) { |n| "Checkbox criterion #{n}" }
    association :assignment
    max_mark { 1.0 }
    ta_visible { true }
    peer_visible { false }
    sequence(:position)
  end
end
