FactoryBot.define do
  factory :lti_service do
    lti_deployment { association(:lti_deployment) }
    service_type { 'namesroles' }
    url { Faker::Internet.url }
  end
end
