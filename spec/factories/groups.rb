require 'faker'

FactoryGirl.define do
  factory :group do
    group_name Faker::Name.first_name
  end
end
