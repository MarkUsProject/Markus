FactoryBot.define do
  factory :lti_client do
    client_id { Faker::Alphanumeric.alpha(number: 12) }
    host { 'https://test.host' }
  end
end
