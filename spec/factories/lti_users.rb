FactoryBot.define do
  factory :lti_user do
    association :lti_client
    association :user
    lti_user_id { Faker::Lorem.unique.characters(number: 20, min_alpha: 1) }
  end
end
