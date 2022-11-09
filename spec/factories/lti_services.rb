FactoryBot.define do
  factory :lti_service do
    association :lti_deployment
    url { Faker::Internet.url }
  end
  factory :lti_service_namesrole, parent: :lti_service do
    service_type { 'namesrole' }
  end
  factory :lti_service_lineitem, parent: :lti_service do
    service_type { 'agslineitem' }
  end
end
