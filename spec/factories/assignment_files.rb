require 'faker'

FactoryBot.define do
  factory :assignment_file do
    association :assignment
    sequence(:filename) { |n| "#{Faker::Lorem.word}_#{n}" }
  end
end
