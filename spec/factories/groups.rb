require 'faker'

FactoryBot.define do
  factory :group do
    sequence(:group_name) { |n| "group#{n}" }
  end
end
