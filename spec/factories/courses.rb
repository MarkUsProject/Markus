FactoryBot.define do
  factory :course do
    sequence(:name) { |i| "C#{i}" }
    sequence(:display_name) { |i| "C#{i}" }
    is_hidden { false }
  end
end
