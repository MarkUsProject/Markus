require 'faker'

FactoryBot.define do
  factory :section do
    association :course
    sequence(:name) { |n| "Section #{n}" }
  end
end
