require 'faker'

FactoryBot.define do
  factory :assignment_properties do
    association :assignment, factory: :assignment
    repository_folder { Faker::Lorem.word }
    token_period { 1 }
  end
end
