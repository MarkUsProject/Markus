require 'faker'

FactoryGirl.define do
  factory :assignment_file do
    association :assignment
    filename { Faker::Lorem.word }
  end
end
