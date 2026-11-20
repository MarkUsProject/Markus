FactoryBot.define do
  factory :lti_line_item do
    association :lti_deployment
    association :assessment, factory: :assignment
    lti_line_item_id { "#{lti_deployment.lti_client.host}/api/lti/courses/1/line_items/#{Faker::Number.number(digits: 6)}" }
  end
end
