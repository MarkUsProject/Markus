FactoryBot.define do
  factory :lti_line_item do
    association :lti_deployment
    association :assessment, factory: :assignment
    lti_line_item_id { Faker::Internet.url }
  end
end
