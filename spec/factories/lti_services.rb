FactoryBot.define do
  factory :lti_service do
    association :lti_deployment
    url { "#{lti_deployment.lti_client.host}/api/lti/courses/#{Faker::Number.number(digits: 4)}/#{Faker::Internet.slug}" }
  end
  factory :lti_service_namesrole, parent: :lti_service do
    service_type { 'namesrole' }
  end
  factory :lti_service_lineitem, parent: :lti_service do
    service_type { 'agslineitem' }
  end
end
