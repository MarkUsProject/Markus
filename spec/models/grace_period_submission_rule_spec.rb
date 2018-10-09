require 'spec_helper'

describe GracePeriodSubmissionRule do
  it 'be able to create GracePeriodSubmissionRule' do
    rule = GracePeriodSubmissionRule.new
    rule.assignment = create(:assignment)
    expect(rule.save).to be_truthy
  end

  context 'When an assignment has two grace periods of 24 hours each after due date' do
    before :each do
      @group = create(:group)
      @grouping = create(:grouping, group: @group)
      @membership = create(:student_membership,
                           grouping: @grouping,
                           membership_status: StudentMembership::STATUSES[:inviter])
      @assignment = @grouping.assignment
      @rule = GracePeriodSubmissionRule.new
      @assignment.replace_submission_rule(@rule)
      GracePeriodDeduction.destroy_all
      @rule.save

      # On July 1 at 1PM, the instructor sets up the course...
      pretend_now_is(Time.parse('July 1 2009 1:00PM')) do
        # Due date is July 23 @ 5PM
        @assignment.due_date = Time.parse('July 23 2009 5:00PM')
        # Add two 24 hour grace periods
        # Overtime begins at July 23 @ 5PM
        add_period_helper(@assignment.submission_rule, 24)
        add_period_helper(@assignment.submission_rule, 24)
        # Collect date is now after July 25 @ 5PM
        @assignment.save
      end
      # On July 15, the Student logs in, triggering repository folder
      # creation
      pretend_now_is(Time.parse('July 15 2009 6:00PM')) do
        @grouping.create_grouping_repository_folder
      end
    end

    teardown do
      destroy_repos
    end

    describe '#calculate_collection_time' do
      it 'is before the current time' do
        expect(Time.now).to be > @rule.calculate_collection_time
      end
    end

    describe '#calculate_grouping_collection_time' do
      it 'is equal to the assignment due date' do
        expect(@rule.calculate_grouping_collection_time(@membership.grouping).to_a).to eq @assignment.due_date.to_a
      end
    end

    describe '#apply_submission_rule' do
      before :each do
        # The Student submits their files before the due date
        submit_file_at_time(@assignment, @group, 'test', 'July 20 2009 5:00PM', 'TestFile.java',
                            'Some contents for TestFile.java')
        submit_file_at_time(@assignment, @group, 'test', 'July 20 2009 5:00PM', 'Test.java',
                            'Some contents for Test.java')
        submit_file_at_time(@assignment, @group, 'test', 'July 20 2009 5:00PM', 'Driver.java',
                            'Some contents for Driver.java')
      end

      teardown do
        destroy_repos
      end

      it 'does not deduct credit for on time submission' do
        # An Instructor or Grader decides to begin grading
        pretend_now_is(Time.parse('July 28 2009 1:00PM')) do
          members = {}
          @grouping.accepted_student_memberships.each do |student_membership|
            members[student_membership.user.id] = student_membership.user.remaining_grace_credits
          end
          submission = Submission.create_by_timestamp(@grouping, @rule.calculate_collection_time)
          @rule.apply_submission_rule(submission)

          @grouping.reload
          @grouping.accepted_student_memberships.each do |student_membership|
            expect(members[student_membership.user.id]).to eq(student_membership.user.remaining_grace_credits)
          end
        end
      end

      it 'deducts a single grace period credit for late submission within first grace period' do
        # Now we're past the due date, but before the collection date.
        submit_file_at_time(@assignment, @group, 'test', 'July 23 2009 9:00PM', 'OvertimeFile.java',
                            'Some overtime contents')

        # Now we're past the collection date.
        submit_file_at_time(@assignment, @group, 'test', 'July 25 2009 10:00PM', 'NotIncluded.java',
                            'Should not be included in grading')

        # An Instructor or Grader decides to begin grading
        pretend_now_is(Time.parse('July 28 2009 1:00PM')) do
          members = {}
          @grouping.accepted_student_memberships.each do |student_membership|
            members[student_membership.user.id] = student_membership.user.remaining_grace_credits
          end
          submission = Submission.create_by_timestamp(@grouping, @rule.calculate_collection_time)
          @rule.apply_submission_rule(submission)

          # Assert that each accepted member of this grouping got a GracePeriodDeduction
          @grouping.reload
          @grouping.accepted_student_memberships.each do |student_membership|
            expect(student_membership.user.remaining_grace_credits).to eq(members[student_membership.user.id] - 1)
          end
        end
      end

      it 'deducts 2 grace credits for late submission within 2 grace credits' do
        # Now we're past the due date, but before the collection date, within the first grace period
        submit_file_at_time(@assignment, @group, 'test', 'July 23 2009 9:00PM', 'OvertimeFile1.java',
                            'Some overtime contents')

        # Now we're past the due date, but before the collection date, within the second grace period
        submit_file_at_time(@assignment, @group, 'test', 'July 24 2009 9:00PM', 'OvertimeFile2.java',
                            'Some overtime contents')

        # Now we're past the collection date.
        submit_file_at_time(@assignment, @group, 'test', 'July 25 2009 10:00PM', 'NotIncluded.java',
                            'Should not be included in grading')

        # An Instructor or Grader decides to begin grading
        pretend_now_is(Time.parse('July 28 2009 1:00PM')) do
          members = {}
          @grouping.accepted_student_memberships.each do |student_membership|
            members[student_membership.user.id] = student_membership.user.remaining_grace_credits
          end
          submission = Submission.create_by_timestamp(@grouping, @rule.calculate_collection_time)
          @rule.apply_submission_rule(submission)

          # Assert that each accepted member of this grouping got 2 GracePeriodDeduction
          @grouping.reload
          @grouping.accepted_student_memberships.each do |student_membership|
            expect(student_membership.user.remaining_grace_credits).to eq(members[student_membership.user.id] - 2)
          end
        end
      end

      it 'deducts 2 grace credits when files are submitted after collection date' do
        # Now we're past the due date, but before the collection date, within the first grace period
        submit_file_at_time(@assignment, @group, 'test', 'July 23 2009 9:00PM', 'OvertimeFile1.java',
                            'Some overtime contents')

        # Now we're past the due date, but before the collection date, within the second grace period
        submit_file_at_time(@assignment, @group, 'test', 'July 24 2009 9:00PM', 'OvertimeFile2.java',
                            'Some overtime contents')

        # Now we're past the collection date.
        submit_file_at_time(@assignment, @group, 'test', 'July 25 2009 10:00PM', 'NotIncluded.java',
                            'Should not be included in grading')

        # An Instructor or Grader decides to begin grading
        pretend_now_is(Time.parse('July 28 2009 1:00PM')) do
          members = {}
          @grouping.accepted_student_memberships.each do |student_membership|
            members[student_membership.user.id] = student_membership.user.remaining_grace_credits
          end
          submission = Submission.create_by_timestamp(@grouping, @rule.calculate_collection_time)
          @rule.apply_submission_rule(submission)

          # Assert that each accepted member of this grouping got 2 GracePeriodDeduction
          @grouping.reload
          @grouping.accepted_student_memberships.each do |student_membership|
            expect(student_membership.user.remaining_grace_credits).to eq(members[student_membership.user.id] - 2)
          end
        end
      end
    end

    context 'with 2 grace credits deduction are in the database for assignment' do
      before :each do
        @grouping.accepted_student_memberships.each do |student_membership|
          deduction = GracePeriodDeduction.new
          deduction.membership = student_membership
          deduction.deduction = 2
          deduction.save
        end

        # The Student submits some files before the due date...
        submit_file_at_time(@assignment, @group, 'test', 'July 20 2009 5:00PM', 'TestFile.java',
                            'Some contents for TestFile.java')
        submit_file_at_time(@assignment, @group, 'test', 'July 20 2009 5:00PM', 'Test.java',
                            'Some contents for Test.java')
        submit_file_at_time(@assignment, @group, 'test', 'July 20 2009 5:00PM', 'Driver.java',
                            'Some contents for Driver.java')
      end

      teardown do
        destroy_repos
      end

      describe '#apply_submission_rule' do
        it 'deducts 1 grace credits when files are submitted within first grace period' do
          # Now we're past the due date, but before the collection date, within the first grace period
          submit_file_at_time(@assignment, @group, 'test', 'July 23 2009 9:00PM', 'OvertimeFile1.java',
                              'Some overtime contents')

          # Now we're past the collection date.
          submit_file_at_time(@assignment, @group, 'test', 'July 25 2009 10:00PM', 'NotIncluded.java',
                              'Should not be included in grading')

          # An Instructor or Grader decides to begin grading
          pretend_now_is(Time.parse('July 28 2009 1:00PM')) do
            members = {}
            @grouping.accepted_student_memberships.each do |student_membership|
              members[student_membership.user.id] = student_membership.user.remaining_grace_credits
            end
            submission = Submission.create_by_timestamp(@grouping, @rule.calculate_collection_time)
            @rule.apply_submission_rule(submission)

            # Assert that each accepted member of this grouping got a GracePeriodDeduction
            @grouping.reload
            @grouping.accepted_student_memberships.each do |student_membership|
              # The students should have 4 grace credits remaining from their 5 grace credits
              expect(student_membership.user.remaining_grace_credits).to eq(4)
            end
          end
        end

        it 'deducts 2 grace credits when files are submitted past the collection date' do
          # Now we're past the due date, but before the collection date, within the first grace period
          submit_file_at_time(@assignment, @group, 'test', 'July 23 2009 9:00PM', 'OvertimeFile1.java',
                              'Some overtime contents')

          # Now we're past the due date, but before the collection date, within the second grace period
          submit_file_at_time(@assignment, @group, 'test', 'July 24 2009 9:00PM', 'OvertimeFile2.java',
                              'Some overtime contents')

          # Now we're past the collection date.
          submit_file_at_time(@assignment, @group, 'test', 'July 25 2009 10:00PM', 'NotIncluded.java',
                              'Should not be included in grading')

          # An Instructor or Grader decides to begin grading
          pretend_now_is(Time.parse('July 28 2009 1:00PM')) do
            members = {}
            @grouping.accepted_student_memberships.each do |student_membership|
              members[student_membership.user.id] = student_membership.user.remaining_grace_credits
            end
            submission = Submission.create_by_timestamp(@grouping, @rule.calculate_collection_time)
            @rule.apply_submission_rule(submission)

            # Assert that each accepted member of this grouping got a GracePeriodDeduction
            @grouping.reload
            @grouping.accepted_student_memberships.each do |student_membership|
              # The students should have 3 grace credits remaining from their 5 grace credits
              expect(student_membership.user.remaining_grace_credits).to eq(3)
            end
          end
        end

        context 'with 1 grace credit remaining' do
          before :each do
            # Set it up so that a member of this Grouping has only 1 (3 grace credits - 2 deductions) grace credit left
            student = @grouping.accepted_student_memberships.first.user
            student.grace_credits = 3
            student.save
          end

          it 'deducts 0 grace credits instead of 2 because there is only 1 remaining' do
            # There should now only be 1 grace credit available for this grouping
            expect(@grouping.available_grace_credits).to eq(1)

            # Now we're past the due date, but before the collection date, within the first grace period.
            # Because one of the students in the Grouping only has one grace credit,
            # OvertimeFile2.java shouldn't be accepted into grading.
            submit_file_at_time(@assignment, @group, 'test', 'July 24 2009 9:00PM', 'OvertimeFile2.java',
                                'Some overtime contents')

            # Now we're past the collection date.
            submit_file_at_time(@assignment, @group, 'test', 'July 25 2009 10:00PM', 'NotIncluded.java',
                                'Should not be included in grading')

            # An Instructor or Grader decides to begin grading
            pretend_now_is(Time.parse('July 28 2009 1:00PM')) do
              members = {}
              @grouping.accepted_student_memberships.each do |student_membership|
                members[student_membership.user.id] = student_membership.user.remaining_grace_credits
              end
              submission = Submission.create_by_timestamp(@grouping, @rule.calculate_collection_time)
              @rule.apply_submission_rule(submission)

              # Assert that each accepted member of this grouping did not get a GracePeriodDeduction
              @grouping.accepted_student_memberships.each do |student_membership|
                student_membership.user.grace_period_deductions.reload
                expect(student_membership.user.remaining_grace_credits).to eq(members[student_membership.user.id])
              end
            end
          end
        end

        context 'with no grace credits remaining' do
          before :each do
            # Set it up so that a member of this Grouping has no (2 grace credits - 2 deductions) grace credits left
            student = @grouping.accepted_student_memberships.first.user
            student.grace_credits = 2
            student.save
          end

          it "does not deduct grace credits because there aren't any of them (0 grace credit left)" do
            # There should now only be 0 grace credit available for this grouping
            expect(@grouping.available_grace_credits).to eq(0)

            # Now we're past the due date, but before the collection date, within the second
            # grace period.  Because one of the students in the Grouping doesn't have any
            # grace credits, OvertimeFile2.java shouldn't be accepted into grading.
            submit_file_at_time(@assignment, @group, 'test', 'July 24 2009 9:00PM', 'OvertimeFile2.java', 'Some overtime contents')

            # Now we're past the collection date.
            submit_file_at_time(@assignment, @group, 'test', 'July 25 2009 10:00PM', 'NotIncluded.java', 'Should not be included in grading')

            # An Instructor or Grader decides to begin grading
            pretend_now_is(Time.parse('July 28 2009 1:00PM')) do
              members = {}
              @grouping.accepted_student_memberships.each do |student_membership|
                members[student_membership.user.id] = student_membership.user.remaining_grace_credits
              end
              submission = Submission.create_by_timestamp(@grouping, @rule.calculate_collection_time)
              @rule.apply_submission_rule(submission)

              # Assert that no grace period deductions got handed out needlessly
              @grouping.reload
              @grouping.accepted_student_memberships.each do |student_membership|
                expect(student_membership.user.remaining_grace_credits).to eq(members[student_membership.user.id])
              end
            end
          end
        end
      end
    end

    context 'submit assignment 1 on time and submit assignment 2 before assignment 1 collection time' do
      before :each do
        @grouping2 = create(:grouping, group: @group)
        @membership2 = create(:student_membership,
                              grouping: @grouping2,
                              membership_status: StudentMembership::STATUSES[:inviter])
        @assignment2 = @grouping2.assignment

        @rule2 = GracePeriodSubmissionRule.new
        @assignment2.replace_submission_rule(@rule2)
        GracePeriodDeduction.destroy_all

        @rule2.save

        # On July 2 at 1PM, the instructor sets up the course...
        pretend_now_is(Time.parse('July 2 2009 1:00PM')) do
          # Due date is July 28 @ 5PM
          @assignment2.due_date = Time.parse('July 28 2009 5:00PM')
          # Add two 24 hour grace periods
          # Overtime begins at July 28 @ 5PM
          add_period_helper(@assignment2.submission_rule, 24)
          add_period_helper(@assignment2.submission_rule, 24)
          # Collect date is now after July 30 @ 5PM
          @assignment2.save
        end
        # On July 16, the Student logs in, triggering repository folder
        # creation
        pretend_now_is(Time.parse('July 16 2009 6:00PM')) do
          @grouping2.create_grouping_repository_folder
        end
      end

      teardown do
        destroy_repos
      end

      describe '#apply_submission_rule' do
        # Regression test for issue 656.  The issue is when submitting files for an assignment before the grace period
        # of the previous assignment is over.  When calculating grace days for the previous assignment, it
        # takes the newer assignment submission as the submission time.  Therefore, grace days are being
        # taken off when it shouldn't have.
        it 'deducts 0 grace credits when submitting on time before grace period of previous assignment is over' do
          # The Student submits some files before the due date...
          submit_file_at_time(@assignment, @group, 'test', 'July 20 2009 5:00PM', 'TestFile.java',
                              'Some contents for TestFile.java')
          submit_file_at_time(@assignment, @group, 'test', 'July 20 2009 5:00PM', 'Test.java',
                              'Some contents for Test.java')
          submit_file_at_time(@assignment, @group, 'test', 'July 20 2009 5:00PM', 'Driver.java',
                              'Some contents for Driver.java')

          # Now we're past the due date, but before the collection date, within the first
          # grace period.  Submit files for Assignment 2
          submit_file_at_time(@assignment2, @group, 'test1', 'July 23 2009 9:00PM', 'NotIncluded.java',
                              'Not Included in Asssignment 1')

          # An Instructor or Grader decides to begin grading
          pretend_now_is(Time.parse('July 31 2009 1:00PM')) do
            members = {}
            @grouping.accepted_student_memberships.each do |student_membership|
              members[student_membership.user.id] = student_membership.user.remaining_grace_credits
            end
            submission = Submission.create_by_timestamp(@grouping, @rule.calculate_collection_time)
            @rule.apply_submission_rule(submission)

            # Assert that each accepted member of this grouping did not get a GracePeriodDeduction
            @grouping.reload
            @grouping.accepted_student_memberships.each do |student_membership|
              expect(student_membership.user.remaining_grace_credits).to eq(members[student_membership.user.id])
            end
          end
        end

        # Regression test for issue 656.  The issue is when submitting files for an assignment before the grace period
        # of the previous assignment is over.  When calculating grace days for the previous assignment, it
        # takes the newer assignment submission as the submission time.  Therefore, grace days are being
        # taken off when it shouldn't have.
        it 'deducts 1 grace credits when submitting overtime before the grace period of previous assignment is over' do
          # The Student submits some files before the due date...
          submit_file_at_time(@assignment, @group, 'test', 'July 20 2009 5:00PM', 'TestFile.java',
                              'Some contents for TestFile.java')
          submit_file_at_time(@assignment, @group, 'test', 'July 20 2009 5:00PM', 'Test.java',
                              'Some contents for Test.java')
          submit_file_at_time(@assignment, @group, 'test', 'July 20 2009 5:00PM', 'Driver.java',
                              'Some contents for Driver.java')

          # Now we're past the due date, but before the collection date, within the first
          # grace period.
          submit_file_at_time(@assignment, @group, 'test', 'July 23 2009 9:00PM', 'OvertimeFile1.java',
                              'Some overtime contents')
          # Submit files for Assignment 2
          submit_file_at_time(@assignment2, @group, 'test1', 'July 24 2009 9:00PM', 'NotIncluded.java',
                              'Not Included in Asssignment 1')

          # An Instructor or Grader decides to begin grading
          pretend_now_is(Time.parse('July 31 2009 1:00PM')) do
            members = {}
            @grouping.accepted_student_memberships.each do |student_membership|
              members[student_membership.user.id] = student_membership.user.remaining_grace_credits
            end
            submission = Submission.create_by_timestamp(@grouping, @rule.calculate_collection_time)
            @rule.apply_submission_rule(submission)

            # Assert that each accepted member of this grouping did not get a GracePeriodDeduction
            @grouping.reload
            @grouping.accepted_student_memberships.each do |student_membership|
              expect(student_membership.user.remaining_grace_credits).to eq(members[student_membership.user.id] - 1)
            end
          end
        end
      end
    end
  end
end
