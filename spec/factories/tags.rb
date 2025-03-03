FactoryBot.define do
  factory :tag, class: 'Tag' do
    association :role, factory: :instructor
    name { Faker::Lorem.unique.word }
    description { Faker::Lorem.sentence }
    assessment_id { nil }
  end
end
