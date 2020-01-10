FactoryBot.define do
  factory :tag, class: Tag do
    association :user, factory: :admin
    name { Faker::Lorem.word }
    description { Faker::Lorem.sentence }
  end
end
