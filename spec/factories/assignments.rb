require 'faker'

FactoryBot.define do
  factory :assignment do
    sequence(:short_identifier) { |i| "A#{i}" }
    description { Faker::Lorem.sentence }
    message { Faker::Lorem.sentence }

    due_date { 1.minute.from_now }
    is_hidden { false }

    transient do
      assignment_properties_attributes { {} }
    end

    after(:build) do |assignment, evaluator|
      if evaluator.assignment_properties_attributes.present?
        assignment.assignment_properties = build(:assignment_properties,
                                                 assignment: assignment,
                                                 repository_folder: assignment.short_identifier,
                                                 attributes: evaluator.assignment_properties_attributes)
      else
        assignment.assignment_properties = build(:assignment_properties,
                                                 assignment: assignment,
                                                 repository_folder: assignment.short_identifier)
      end
    end
  end

  factory :assignment_with_criteria_and_results, parent: :assignment do
    after(:create) do |a|
      3.times { create(:flexible_criterion, assignment: a) }
      3.times { create(:grouping_with_inviter_and_submission, assignment: a) }
      a.groupings.each do |grouping|
        result = grouping.current_result
        result.marks.each do |mark|
          mark.update(mark: rand(mark.criterion.max_mark + 1))
        end
        result.update_total_mark
        result.update(marking_state: Result::MARKING_STATES[:complete])
      end
      a.update_results_stats
    end
  end

  factory :assignment_with_deductive_annotations, parent: :assignment do
    # This factory creates an assignment with three groupings that each have a result.
    # The assignment has a flexible_criterion with a max_mark of 3.0.
    # The assignment also has an annotation_category that belongs to the flexible criterion.
    # The assignment's annotation category has one annotation_text with a deduction of 1.0.
    # Each grouping's result has one annotation which belongs to the annotation_text mentioned.
    after(:create) do |a|
      create(:flexible_criterion_with_annotation_category, assignment: a)
      3.times { create(:grouping_with_inviter_and_submission, assignment: a) }
      a.groupings.each do |grouping|
        result = grouping.current_result
        create(:text_annotation,
               annotation_text: a.annotation_categories.first.annotation_texts.first,
               result: result)
        result.update_total_mark
      end
    end
  end

  factory :assignment_with_peer_review, parent: :assignment do
    assignment_properties_attributes { { has_peer_review: true } }
  end

  factory :peer_review_assignment, parent: :assignment do
    association :parent_assignment, factory: :assignment_with_peer_review
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
    after(:build) do |assignment, evaluator| # called by both create and build
      properties = { enable_test: true }
      evaluator.assignment_properties_attributes = properties.merge(evaluator.assignment_properties_attributes)

      create(:test_group, assignment: assignment)
    end
  end

  factory :assignment_for_student_tests, parent: :assignment do
    after(:build) do |assignment, evaluator| # called by both create and build
      properties = { enable_test: true, enable_student_tests: true, token_start_date: Time.current }
      evaluator.assignment_properties_attributes = properties.merge(evaluator.assignment_properties_attributes)

      create(:test_group, assignment: assignment)
    end
  end

  factory :assignment_for_scanned_exam, parent: :assignment do
    after :build do |_assignment, evaluator|
      properties =  { scanned_exam: true }
      evaluator.assignment_properties_attributes = properties.merge(evaluator.assignment_properties_attributes)
    end
  end

  factory :timed_assignment, parent: :assignment do
    after :build do |_assignment, evaluator|
      properties =  { is_timed: true, duration: 1.hour + 30.minutes, start_time: 10.hours.ago }
      evaluator.assignment_properties_attributes = properties.merge(evaluator.assignment_properties_attributes)
    end
  end
end
