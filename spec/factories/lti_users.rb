FactoryBot.define do
  factory :lti_user do
    association :lti_client
    association :user
    lti_user_id { Faker::Lorem.word }
  end
end
