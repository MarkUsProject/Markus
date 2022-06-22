FactoryBot.define do
  factory :lti_client do
    client_id { Faker::Lorem.word }
    host { Faker::Internet.domain_name }
  end
end
