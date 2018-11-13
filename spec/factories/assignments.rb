require 'faker'

FactoryBot.define do
  factory :assignment do
    sequence(:short_identifier) { |i| "A#{i}" }
    description { Faker::Lorem.sentence }
    message { Faker::Lorem.sentence }
    repository_folder { Faker::Lorem.word }
    due_date { 1.minute.from_now }
    submission_rule { NoLateSubmissionRule.new }
    assignment_stat { AssignmentStat.new }
    token_period { 1 }
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
end
