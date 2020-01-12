require 'faker'

FactoryBot.define do
  factory :assignment do
    sequence(:short_identifier) { |i| "A#{i}" }
    description { Faker::Lorem.sentence }
    message { Faker::Lorem.sentence }

    due_date { 1.minute.from_now }
    submission_rule { NoLateSubmissionRule.new }
    assignment_stat { AssignmentStat.new }

    transient do
      assignment_properties_attributes { nil }
    end

    after(:build) do |assignment, evaluator|
      if evaluator.assignment_properties_attributes
        assignment.assignment_properties ||= build(:assignment_properties,
                                                   assignment: assignment,
                                                   attributes: evaluator.assignment_properties_attributes)
      else
        assignment.assignment_properties ||= build(:assignment_properties, assignment: assignment)
      end
    end
  end

  factory :assignment_with_peer_review, parent: :assignment do
    has_peer_review { true }
  end

  # This creates an assignment and peer review assignment, and also creates the
  # necessary groups/submissions/results/etc, such that PeerReview entries can
  # be created from this using such functions as random assignment.
  factory :assignment_with_peer_review_and_groupings_results, parent: :assignment_with_peer_review do
    after(:create) do |assign|
        students = 6.times.map { (create(:student)) }
        groupings = 3.times.map { create(:grouping, assignment: assign) }
        pr_groupings = 3.times.map { create(:grouping, assignment: assign.pr_assignment) }
        3.times.each { |i| create(:accepted_student_membership, user: students[i], grouping: groupings[i]) }
        3.times.each { |i| create(:accepted_student_membership, user: students[i+3], grouping: pr_groupings[i]) }
        submissions = 3.times.map { |i| create(:version_used_submission, grouping: groupings[i]) }
        3.times.each { |i| create(:result, submission: submissions[i], marking_state: Result::MARKING_STATES[:complete]) }
    end
  end

  factory :assignment_for_tests, parent: :assignment do
    enable_test { true }
    after(:build) do |assignment| # called by both create and build
      create(:test_group, assignment: assignment)
    end
    after(:stub) do |assignment| # called by build_stubbed
      build_stubbed(:test_group, assignment: assignment)
    end
  end

  factory :assignment_for_student_tests, parent: :assignment_for_tests do
    enable_student_tests { true }
    token_start_date { Time.current }
  end

  factory :assignment_for_scanned_exam, parent: :assignment do
    scanned_exam { true }
  end
end
