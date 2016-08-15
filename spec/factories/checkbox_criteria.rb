FactoryGirl.define do
  factory :checkbox_criterion do
    sequence(:name) { |n| "Checkbox criterion #{n}" }
    association :assignment, factory: :assignment
    max_mark 1.0
    ta_visible true
    peer_visible false
  end
end

