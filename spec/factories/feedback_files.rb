FactoryBot.define do
  factory :feedback_file do
    association :submission
    filename { "#{Faker::Lorem.word}.txt" }
    mime_type { 'text/plain' }
    file_content { Faker::Lorem.sentence }
  end

  factory :feedback_file_with_test_run, class: 'FeedbackFile' do
    association :test_group_result
    filename { "#{Faker::Lorem.word}.txt" }
    mime_type { 'text/plain' }
    file_content { Faker::Lorem.sentence }
  end
end
