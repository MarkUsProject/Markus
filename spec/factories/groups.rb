require 'faker'

FactoryGirl.define do
  factory :group do
    group_name { Faker::Lorem.word }
  end
end
