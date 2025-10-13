FactoryBot.define do
  factory :extra_mark do
    association :result
    description { Faker::Lorem.sentence }
    unit { 'percentage' }
    extra_mark { -10.0 }
  end
  factory :extra_mark_points, class: 'ExtraMark' do
    association :result
    description { Faker::Lorem.sentence }
    unit { 'points' }
    extra_mark { 1 }
  end
  factory :extra_mark_percentage_of_score, class: 'ExtraMark' do
    association :result
    description { Faker::Lorem.sentence }
    unit { 'percentage_of_score' }
    extra_mark { 5.0 }
  end
end
