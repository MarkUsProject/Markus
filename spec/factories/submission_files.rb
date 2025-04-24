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

    factory :rmd_submission_file do
      filename { "#{Faker::Lorem.word}.Rmd" }
    end
  end

  factory :submission_file_with_repo, parent: :submission_file do
    after(:create) do |sf|
      sf.submission.grouping.group.access_repo do |repo|
        txn = repo.get_transaction('test')
        txn.add(sf.path, sf.filename, '')
        repo.commit(txn)
      end
    end

    factory :image_submission_file_with_repo do
      filename { "#{Faker::Lorem.word}.jpg" }
    end

    factory :pdf_submission_file_with_repo do
      filename { "#{Faker::Lorem.word}.pdf" }
    end

    factory :notebook_submission_file_with_repo do
      filename { "#{Faker::Lorem.word}.ipynb" }
    end
  end

  factory :rmd_submission_file_with_repo do
    filename { "#{Faker::Lorem.word}.Rmd" }
  end
end
