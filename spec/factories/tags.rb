FactoryBot.define do
  factory :tag, class: Tag do
    association :role, factory: :instructor
    name { Faker::Lorem.word }
    description { Faker::Lorem.sentence }
  end
end
