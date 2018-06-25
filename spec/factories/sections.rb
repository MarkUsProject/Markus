require 'faker'

FactoryBot.define do
  factory :section do
    sequence(:name) { |n| "Section #{n}" }
  end
end
