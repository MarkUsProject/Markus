FactoryBot.define do
  factory :test_group do
    association :assignment
    name { Faker::Lorem.word }

    factory :test_group_with_ordered_name do
      sequence :name do |n|
        "Test Group #{n}"
      end
    end
  end
end
