require 'faker'

FactoryBot.define do
  factory :test_server, class: TestServer do
    user_name MarkusConfigurator.autotest_server_host
    last_name { Faker::Name.last_name }
    first_name { Faker::Name.first_name }
  end
end
