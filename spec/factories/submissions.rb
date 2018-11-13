FactoryBot.define do
  factory :submission do
    association :grouping
    submission_version { 1 }
    revision_identifier { 1 }
    revision_timestamp { Date.current }

    factory :version_used_submission do
      submission_version_used { true }
    end
  end
end
