require 'faker'

FactoryGirl.define do
  factory :test_script, class: TestScript do
    association :assignment
    file_name "#{Faker::Lorem}.txt"
    sequence(:seq_num) {|s| "#{s}"}
    description Faker::Lorem
    run_by_instructors true
    run_by_students true
    halts_testing false
    display_description "display_after_submission"
    display_run_status "display_after_submission"
    display_marks_earned "display_after_submission"
    display_input "display_after_submission"
    display_expected_output "display_after_submission"
    display_actual_output "display_after_submission"
    timeout 10
  end
end
