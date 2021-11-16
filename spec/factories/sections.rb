require 'faker'

FactoryBot.define do
  factory :section do
    course { Course.first || association(:course) }
    sequence(:name) { |n| "Section #{n}" }
  end
end
