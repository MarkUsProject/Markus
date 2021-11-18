FactoryBot.define do
  factory :tag, class: Tag do
    association :user, factory: :admin
    name { Faker::Lorem.word }
    description { Faker::Lorem.sentence }
    assessment_id { nil }
  end
end
