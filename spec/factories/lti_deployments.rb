FactoryBot.define do
  factory :lti_deployment do
    association :lti_client
    association :course
    external_deployment_id { Faker::Lorem.word }
  end
end
