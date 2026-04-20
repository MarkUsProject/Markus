FactoryBot.define do
  factory :lti_deployment do
    association :lti_client
    external_deployment_id { Faker::Lorem.word }
    lms_course_name { Faker::Lorem.word }
    lms_course_id { Faker::Number.number(digits: 2) }

    trait :scs_winter do
      lms_term_name { 'SCS Winter 2026' }
    end
  end
end
