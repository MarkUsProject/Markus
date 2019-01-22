FactoryBot.define do
  factory :submission_file, class: SubmissionFile do
    association :submission
    filename { Faker::Lorem.word }
    path { Faker::Lorem.word }
  end
end
