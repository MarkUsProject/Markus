FactoryGirl.define do
  factory :user do
    sequence(:user_name) { |n| Faker::Internet.user_name + n.to_s }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
  end
  
  factory :user2, class: User do
    user_name 'c8shosta'
    type 'Student'
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
  end
  
end
