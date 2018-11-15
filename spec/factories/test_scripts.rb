FactoryBot.define do
  factory :test_script do
    association :assignment
    seq_num { 1 }
    file_name { Faker::File.file_name }
    description { Faker::Lorem.sentence }
    display_description { 'display_after_submission' }
    display_run_status { 'display_after_submission' }
    display_marks_earned { 'display_after_submission' }
    display_input { 'display_after_submission' }
    display_expected_output { 'display_after_submission' }
    display_actual_output { 'display_after_submission' }
    timeout { 10 }
  end
end
