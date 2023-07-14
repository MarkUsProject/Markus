FactoryBot.define do
  factory :submission do
    association :grouping
    submission_version { 1 }
    revision_identifier { 1 }
    revision_timestamp { Date.current }
    is_empty { false }

    factory :version_used_submission do
      submission_version_used { true }
      factory :version_used_submission_accurate_revision do
        revision_timestamp { Time.current }
      end
    end
  end
end
