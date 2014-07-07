FactoryGirl.define do
  factory :user do
    user_name { Faker::Internet.user_name }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
  end
end
