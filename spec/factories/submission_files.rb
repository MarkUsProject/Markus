FactoryBot.define do
  factory :submission_file do
    association :submission
    filename { "#{Faker::Lorem.word}.txt" }
    path { submission.grouping.assignment.repository_folder || Faker::Lorem.word }

    factory :image_submission_file do
      filename { "#{Faker::Lorem.word}.jpg" }
    end

    factory :pdf_submission_file do
      filename { "#{Faker::Lorem.word}.pdf" }
    end

    factory :notebook_submission_file do
      filename { "#{Faker::Lorem.word}.ipynb" }
    end
  end
end
