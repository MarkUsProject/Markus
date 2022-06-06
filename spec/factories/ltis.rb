FactoryBot.define do
  factory :lti do
    client_id { Faker::Lorem.word }
    deployment_id { Faker::Lorem.word }
  end
end
