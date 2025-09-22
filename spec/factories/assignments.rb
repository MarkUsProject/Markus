require 'faker'

FactoryBot.define do
  factory :assignment do
    course { Course.order(:id).first || association(:course) }
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
      create_list(:flexible_criterion, 3, assignment: a)
      create_list(:grouping_with_inviter_and_submission, 3, assignment: a)
      a.groupings.each do |grouping|
        result = grouping.current_result
        result.marks.each do |mark|
          mark.update(mark: rand(mark.criterion.max_mark + 1))
        end
        result.update(marking_state: Result::MARKING_STATES[:complete])
      end
    end
  end

  factory :assignment_with_criteria_and_released_results, parent: :assignment_with_criteria_and_results do
    after(:create) do |a|
      # Release marks by setting released_to_students to true on all current results
      a.current_results.update_all(released_to_students: true)
    end
  end

  factory :assignment_with_criteria_and_test_results, parent: :assignment do
    after(:create) do |a|
      create_list(:flexible_criterion, 3, assignment: a)
      create_list(:grouping_with_inviter_and_submission, 3, assignment: a)
      create_list(:test_group, 3, assignment: a)

      a.groupings.each do |grouping|
        a.test_groups.each do |test_group|
          5.times do
            test_run = create(:test_run, grouping: grouping, submission_id: grouping.current_submission_used.id)
            test_group_result = create(:test_group_result, test_run: test_run, test_group: test_group)
            create(:test_result, test_group_result: test_group_result)
          end
        end
      end
    end
  end

  factory :static_assignment_with_criteria_and_test_results, parent: :assignment do
    # This factory generates an assignment with test results that have group, test_group and test_result
    # names that match the most_recent_test_results.csv fixture file.
    after(:create) do |a|
      create_list(:flexible_criterion, 3, assignment: a)
      create_list(:grouping_with_inviter_and_submission, 3, assignment: a)
      create_list(:test_group, 3, assignment: a)

      a.groupings.each do |grouping|
        test_run = create(:test_run, grouping: grouping, submission_id: grouping.current_result.submission.id)
        a.test_groups.order(:id).each_with_index do |test_group, i|
          test_group_result = create(:test_group_result, test_run: test_run, test_group: test_group)
          create(:test_result, test_group_result: test_group_result, name: "Test Case #{i + 1}")
        end
      end
    end
  end

  factory :assignment_with_criteria_and_results_and_tas, parent: :assignment_with_criteria_and_results do
    after(:create) do |a|
      a.groupings.each do |grouping|
        ta = create(:ta)
        create(:ta_membership, role: ta, grouping: grouping)
      end
    end
  end

  factory :assignment_with_criteria_and_results_with_remark, parent: :assignment do
    after(:create) do |a|
      create_list(:flexible_criterion, 3, assignment: a)
      create_list(:grouping_with_inviter_and_submission, 3, assignment: a)
      a.groupings.each_with_index do |grouping, i|
        result = grouping.current_result
        result.marks.each do |mark|
          mark.update(mark: mark.criterion.max_mark - 1)
        end
        result.update!(marking_state: Result::MARKING_STATES[:complete], created_at: 1.minute.ago)
        grouping.current_submission_used.remark_request_timestamp = 1.minute.ago
        if i.zero?
          grouping.current_submission_used.make_remark_result
          remark_result = grouping.current_submission_used.current_result
          remark_result.marks.each do |mark|
            mark.update!(mark: mark.criterion.max_mark)
          end
          remark_result.update!(marking_state: Result::MARKING_STATES[:complete])
        end
      end
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
      create_list(:grouping_with_inviter_and_submission, 3, assignment: a)
      a.groupings.each do |grouping|
        result = grouping.current_result
        create(:text_annotation,
               annotation_text: a.annotation_categories.first.annotation_texts.first,
               result: result)
      end
    end
  end

  factory :assignment_with_deductive_annotations_and_submission_files, parent: :assignment_with_deductive_annotations do
    after(:create) do |a|
      a.groupings.each do |grouping|
        grouping.current_result.annotations.each do |annotation|
          # make physical submission files for each one
          annotation.submission_file = create(:submission_file_with_repo,
                                              filename: annotation.submission_file.filename,
                                              submission: grouping.current_submission_used)
        end
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
      students = create_list(:student, 6)
      groupings = create_list(:grouping, 3, assignment: assign)
      pr_groupings = create_list(:grouping, 3, assignment: assign.pr_assignment)
      3.times.each do |i|
        create(:accepted_student_membership, role: students[i], grouping: groupings[i])
        create(:accepted_student_membership, role: students[i + 3], grouping: pr_groupings[i])

        create(:version_used_submission, grouping: groupings[i])
        groupings[i].reload
      end
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
      properties = { scanned_exam: true }
      evaluator.assignment_properties_attributes = properties.merge(evaluator.assignment_properties_attributes)
    end
  end

  factory :timed_assignment, parent: :assignment do
    after :build do |_assignment, evaluator|
      properties = { is_timed: true, duration: 1.hour + 30.minutes, start_time: 10.hours.ago }
      evaluator.assignment_properties_attributes = properties.merge(evaluator.assignment_properties_attributes)
    end
  end

  factory :assignment_with_test_groups_student_runnable, parent: :assignment do
    after(:create) do |a|
      create(:test_group_student_runnable, assignment: a)
      create_list(:test_group, 2, assignment: a)
    end
  end

  factory :assignment_with_test_groups_not_student_runnable, parent: :assignment do
    after(:create) do |a|
      create_list(:test_group, 3, assignment: a)
    end
  end

  factory :assignment_with_test_groups_instructor_runnable, parent: :assignment do
    after(:create) do |a|
      create(:test_group_instructor_runnable, assignment: a)
      create_list(:test_group, 2, assignment: a)
    end
  end

  factory :assignment_with_test_groups_not_instructor_runnable, parent: :assignment do
    after(:create) do |a|
      create_list(:test_group, 3, assignment: a)
    end
  end

  factory :assignment_with_criteria_and_results_and_extra_marks, parent: :assignment_with_criteria_and_results do
    after(:create) do |a|
      a.groupings.each do |grouping|
        create(:extra_mark_points, result: grouping.current_result)
      end
    end
  end

  factory :assignment_with_criteria_and_results_and_feedback_files, parent: :assignment_with_criteria_and_results do
    after(:create) do |a|
      a.current_submissions_used.each do |s|
        create_list(:feedback_file, 3, submission: s)
      end
    end
  end

  factory :assignment_with_criteria_and_test_results_and_feedback_files,
          parent: :assignment_with_criteria_and_test_results do
    after(:create) do |a|
      a.groupings.each do |g|
        g.test_runs.each do |tr|
          tr.test_group_results.each do |tgr|
            create(:feedback_file, test_group_result: tgr)
          end
        end
      end
    end
  end
end
