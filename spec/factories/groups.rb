require 'faker'

FactoryGirl.define do
  factory :group do
    group_name { Faker::Internet.user_name }
  end
end
