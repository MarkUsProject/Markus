FactoryBot.define do
  factory :lti_deployment do
    association :lti_client
    external_deployment_id { Faker::Lorem.word }
  end
end
