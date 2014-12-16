require 'faker'

FactoryGirl.define do
  factory :assignment_file do
    association :assignment
    filename { Faker::Hacker::noun }
  end
end
