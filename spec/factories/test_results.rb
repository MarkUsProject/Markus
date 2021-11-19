FactoryBot.define do
  factory :test_result do
    name { Faker::Lorem.word }
    status { 'pass' }
    marks_earned { 1 }
    output { Faker::TvShows::HeyArnold.quote }
    marks_total { 1 }
    association :test_group_result
    time { Faker::Number.number(digits: 4) }

    factory :test_result_with_ordered_name do
      sequence :name do |n|
        "Test Result #{n}"
      end
    end
  end
end
