FactoryBot.define do
  factory :extra_mark do
    association :result
    description { Faker::Lorem.sentence }
    unit { 'percentage' }
    extra_mark { -10.0 }
  end
end
