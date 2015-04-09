FactoryGirl.define do
  factory :user do
    sequence(:user_name) { |n| Faker::Internet.user_name + n.to_s }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
  end
  
  factory :user_UTF_8, class: User do
    user_name 'c2ÈrÉØrr'
    #sequence(:user_name) { |n| Faker::Internet.user_name + n.to_s }
    type 'Student'
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
  end
  
  factory :user_ISO_8859, class: User do
    user_name 'c2»r…ÿrr'
    #sequence(:user_name) { |n| Faker::Internet.user_name + n.to_s }
    type 'Student'
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
  end
  
end
