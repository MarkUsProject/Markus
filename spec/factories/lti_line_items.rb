FactoryBot.define do
  factory :lti_line_item do
    association :lti_deployment
    lti_line_item_id { Faker::Internet.url }
  end
end
