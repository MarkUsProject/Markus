require 'faker'

FactoryGirl.define do
  factory :section do
    name { Faker::Lorem.word }
  end
end
