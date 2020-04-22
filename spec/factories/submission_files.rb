FactoryBot.define do
  factory :submission_file do
    association :submission
    filename { "#{Faker::Lorem.word}.txt" }
    path { Faker::Lorem.word }

    factory :image_submission_file do
      filename { "#{Faker::Lorem.word}.jpg" }
    end

    factory :pdf_submission_file do
      filename { "#{Faker::Lorem.word}.pdf" }
    end
  end
end
