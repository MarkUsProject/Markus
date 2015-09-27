require 'faker'

FactoryGirl.define do
  factory :group do
    sequence(:group_name) { |n| "group#{n}" }
  end
end
