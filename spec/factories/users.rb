FactoryBot.define do
  factory :user do
    sequence(:user_name) { |n| Faker::Internet.user_name(separators: %w[_ -]) + n.to_s }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    email { Faker::Internet.email }
    display_name { "#{first_name} #{last_name}" }
    type { 'Standard' }
  end
end
