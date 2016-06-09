require File.expand_path(File.join(File.dirname(__FILE__), '..', 'test_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'blueprints', 'helper'))

require 'shoulda'
require 'time-warp'

include MarkusConfigurator

class GracePeriodSubmissionRuleTest < ActiveSupport::TestCase
  context 'Assignment has two grace periods of 24 hours each after due date' do
    setup do
      @assignment = Assignment.make
      @group = Group.make
      @student = Student.make
      @grouping = Grouping.make(assignment: @assignment,
                                group: @group)

      StudentMembership.make(grouping: @grouping,
                             membership_status: 'inviter',
                             user: @student)
      grace_period_submission_rule = GracePeriodSubmissionRule.new
      @assignment.replace_submission_rule(grace_period_submission_rule)
      GracePeriodDeduction.destroy_all

      grace_period_submission_rule.save

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

    should 'deduct a single grace credit' do
      # The Student submits some files before the due date...
      submit_files_before_due_date

      # Now we're past the due date, but before the collection date.
      submit_files_after_due_date_before_collection_time('July 23 2009 9:00PM', 'OvertimeFile.java', 'Some overtime contents')

      # Now we're past the collection date.
      submit_files_after_due_date_after_collection_time('July 25 2009 10:00PM', 'NotIncluded.java', 'Should not be included in grading')

      pretend_now_is(Time.parse('July 25 2009 10:00PM')) do
        assert Time.now > @assignment.due_date
        assert Time.now > @assignment.submission_rule.calculate_collection_time
        assert Time.now > @assignment.submission_rule.calculate_grouping_collection_time(@grouping)
        @group.access_repo do |repo|
          txn = repo.get_transaction('test')
          txn = add_file_helper(@assignment, txn, 'NotIncluded.java', 'Should not be included in grading')
          repo.commit(txn)
        end
      end

      # An Instructor or Grader decides to begin grading
      pretend_now_is(Time.parse('July 28 2009 1:00PM')) do
        members = {}
        @grouping.accepted_student_memberships.each do |student_membership|
          members[student_membership.user.id] = student_membership.user.remaining_grace_credits
        end
        submission = Submission.create_by_timestamp(@grouping, @assignment.submission_rule.calculate_collection_time)
        submission = @assignment.submission_rule.apply_submission_rule(submission)

        # Assert that each accepted member of this grouping got a GracePeriodDeduction
        @grouping.reload
        @grouping.accepted_student_memberships.each do |student_membership|
          assert_equal members[student_membership.user.id] - 1, student_membership.user.remaining_grace_credits
        end

        # We should have all files except NotIncluded.java in the repository.
        assert_not_nil submission.submission_files.find_by_filename('TestFile.java')
        assert_not_nil submission.submission_files.find_by_filename('Test.java')
        assert_not_nil submission.submission_files.find_by_filename('Driver.java')
        assert_not_nil submission.submission_files.find_by_filename('OvertimeFile.java')
        assert_nil submission.submission_files.find_by_filename('NotIncluded.java')
        assert_not_nil submission.get_latest_result
      end

    end

    should 'deduct 2 grace credits' do
      # The Student submits some files before the due date...
      submit_files_before_due_date

      # Now we're past the due date, but before the collection date, within the first
      # grace period
      submit_files_after_due_date_before_collection_time('July 23 2009 9:00PM', 'OvertimeFile1.java', 'Some overtime contents')

      # Now we're past the due date, but before the collection date, within the second
      # grace period
      submit_files_after_due_date_before_collection_time('July 24 2009 9:00PM', 'OvertimeFile2.java', 'Some overtime contents')

      # Now we're past the collection date.
      submit_files_after_due_date_after_collection_time('July 25 2009 10:00PM', 'NotIncluded.java', 'Should not be included in grading')

      # An Instructor or Grader decides to begin grading
      pretend_now_is(Time.parse('July 28 2009 1:00PM')) do
        members = {}
        @grouping.accepted_student_memberships.each do |student_membership|
          members[student_membership.user.id] = student_membership.user.remaining_grace_credits
        end
        submission = Submission.create_by_timestamp(@grouping, @assignment.submission_rule.calculate_collection_time)
        submission = @assignment.submission_rule.apply_submission_rule(submission)

        # Assert that each accepted member of this grouping got a GracePeriodDeduction
        @grouping.reload
        @grouping.accepted_student_memberships.each do |student_membership|
          assert_equal members[student_membership.user.id] - 2, student_membership.user.remaining_grace_credits
        end

        # We should have all files except NotIncluded.java in the repository.
       assert_not_nil submission.submission_files.find_by_filename('TestFile.java')
       assert_not_nil submission.submission_files.find_by_filename('Test.java')
       assert_not_nil submission.submission_files.find_by_filename('Driver.java')
       assert_not_nil submission.submission_files.find_by_filename('OvertimeFile1.java')
       assert_not_nil submission.submission_files.find_by_filename('OvertimeFile2.java')
       assert_nil submission.submission_files.find_by_filename('NotIncluded.java')
       assert_not_nil submission.get_latest_result

     end

    end

    context '2 grace credits deduction are in the database for assignment' do
      setup do
        # 2 grace credits deduction per student are in the database
        @grouping.accepted_student_memberships.each do |student_membership|
          deduction = GracePeriodDeduction.new
          deduction.membership = student_membership
          deduction.deduction = 2
          deduction.save
        end
      end

      should 'deduct 1 grace credits' do

        # The Student submits some files before the due date...
        submit_files_before_due_date

        # Now we're past the due date, but before the collection date, within the first
        # grace period
        submit_files_after_due_date_before_collection_time('July 23 2009 9:00PM', 'OvertimeFile1.java', 'Some overtime contents')

        # Now we're past the collection date.
        submit_files_after_due_date_after_collection_time('July 25 2009 10:00PM', 'NotIncluded.java', 'Should not be included in grading')

        # An Instructor or Grader decides to begin grading
        pretend_now_is(Time.parse('July 28 2009 1:00PM')) do
          members = {}
          @grouping.accepted_student_memberships.each do |student_membership|
            members[student_membership.user.id] = student_membership.user.remaining_grace_credits
          end
          submission = Submission.create_by_timestamp(@grouping, @assignment.submission_rule.calculate_collection_time)
          submission = @assignment.submission_rule.apply_submission_rule(submission)

          # Assert that each accepted member of this grouping got a GracePeriodDeduction
          @grouping.reload
          @grouping.accepted_student_memberships.each do |student_membership|
            # The students should have 1 grace credits remaining from their 5 grace credits
            assert_equal 4, student_membership.user.remaining_grace_credits
          end

          # We should have all files except NotIncluded.java in the repository.
         assert_not_nil submission.submission_files.find_by_filename('TestFile.java')
         assert_not_nil submission.submission_files.find_by_filename('Test.java')
         assert_not_nil submission.submission_files.find_by_filename('Driver.java')
         assert_not_nil submission.submission_files.find_by_filename('OvertimeFile1.java')
         assert_nil submission.submission_files.find_by_filename('NotIncluded.java')
         assert_not_nil submission.get_latest_result

        end

      end

      should 'deduct 2 grace credits' do

        # The Student submits some files before the due date...
        submit_files_before_due_date

        # Now we're past the due date, but before the collection date, within the first
        # grace period
        submit_files_after_due_date_before_collection_time('July 23 2009 9:00PM', 'OvertimeFile1.java', 'Some overtime contents')

        # Now we're past the due date, but before the collection date, within the second
        # grace period
        submit_files_after_due_date_before_collection_time('July 24 2009 9:00PM', 'OvertimeFile2.java', 'Some overtime contents')

        # Now we're past the collection date.
        submit_files_after_due_date_after_collection_time('July 25 2009 10:00PM', 'NotIncluded.java', 'Should not be included in grading')

        # An Instructor or Grader decides to begin grading
        pretend_now_is(Time.parse('July 28 2009 1:00PM')) do
          members = {}
          @grouping.accepted_student_memberships.each do |student_membership|
            members[student_membership.user.id] = student_membership.user.remaining_grace_credits
          end
          submission = Submission.create_by_timestamp(@grouping, @assignment.submission_rule.calculate_collection_time)
          submission = @assignment.submission_rule.apply_submission_rule(submission)

          # Assert that each accepted member of this grouping got a GracePeriodDeduction
          @grouping.reload
          @grouping.accepted_student_memberships.each do |student_membership|
            # The students should have 1 grace credits remaining from their 5 grace credits
            assert_equal 3, student_membership.user.remaining_grace_credits
          end

          # We should have all files except NotIncluded.java in the repository.
         assert_not_nil submission.submission_files.find_by_filename('TestFile.java')
         assert_not_nil submission.submission_files.find_by_filename('Test.java')
         assert_not_nil submission.submission_files.find_by_filename('Driver.java')
         assert_not_nil submission.submission_files.find_by_filename('OvertimeFile1.java')
         assert_not_nil submission.submission_files.find_by_filename('OvertimeFile2.java')
         assert_nil submission.submission_files.find_by_filename('NotIncluded.java')
         assert_not_nil submission.get_latest_result

        end

      end

    end

    should "not deduct grace credits because there aren't enough of them (1 grace credit left)" do

      # Set it up so that a member of this Grouping has only 1 grace credit left
      student = @grouping.accepted_student_memberships.first.user
      student.grace_credits = 1
      student.save

      # There should now only be 1 grace credit available for this grouping
      assert_equal 1, @grouping.available_grace_credits

      # The Student submits some files before the due date...
      submit_files_before_due_date

      # Now we're past the due date, but before the collection date, within the second
      # grace period.  Because one of the students in the Grouping only has one grace credit,
      #  OvertimeFile2.java shouldn't be accepted into grading.
      submit_files_after_due_date_before_collection_time('July 24 2009 9:00PM', 'OvertimeFile2.java', 'Some overtime contents')

      # Now we're past the collection date.
      submit_files_after_due_date_after_collection_time('July 25 2009 10:00PM', 'NotIncluded.java', 'Should not be included in grading')

      # An Instructor or Grader decides to begin grading
      pretend_now_is(Time.parse('July 28 2009 1:00PM')) do
        members = {}
        @grouping.accepted_student_memberships.each do |student_membership|
          members[student_membership.user.id] = student_membership.user.remaining_grace_credits
        end
        submission = Submission.create_by_timestamp(@grouping, @assignment.submission_rule.calculate_collection_time)
        submission = @assignment.submission_rule.apply_submission_rule(submission)

        # Assert that each accepted member of this grouping got a GracePeriodDeduction
        @grouping.accepted_student_memberships.each do |student_membership|
          assert_equal members[student_membership.user.id], student_membership.user.remaining_grace_credits
        end

        # We should have all files except NotIncluded.java in the repository.
        assert_not_nil submission.submission_files.find_by_filename('TestFile.java')
        assert_not_nil submission.submission_files.find_by_filename('Test.java')
        assert_not_nil submission.submission_files.find_by_filename('Driver.java')
        assert_nil submission.submission_files.find_by_filename('OvertimeFile2.java')
        assert_nil submission.submission_files.find_by_filename('NotIncluded.java')
        assert_not_nil submission.get_latest_result
      end

    end

    should "not deduct grace credits because there aren't any of them (0 grace credit left)" do

      # Set it up so that a member of this Grouping has no grace credits
      student = @grouping.accepted_student_memberships.first.user
      student.grace_credits = 0
      student.save

      # There should now only be 0 grace credit available for this grouping
      assert_equal 0, @grouping.available_grace_credits

      # The Student submits some files before the due date...
      submit_files_before_due_date

      # Now we're past the due date, but before the collection date, within the second
      # grace period.  Because one of the students in the Grouping doesn't have any
      # grace credits, OvertimeFile2.java shouldn't be accepted into grading.
      submit_files_after_due_date_before_collection_time('July 24 2009 9:00PM', 'OvertimeFile2.java', 'Some overtime contents')

      # Now we're past the collection date.
      submit_files_after_due_date_after_collection_time('July 25 2009 10:00PM', 'NotIncluded.java', 'Should not be included in grading')

      # An Instructor or Grader decides to begin grading
      pretend_now_is(Time.parse('July 28 2009 1:00PM')) do
        members = {}
        @grouping.accepted_student_memberships.each do |student_membership|
          members[student_membership.user.id] = student_membership.user.remaining_grace_credits
        end
        submission = Submission.create_by_timestamp(@grouping, @assignment.submission_rule.calculate_collection_time)
        submission = @assignment.submission_rule.apply_submission_rule(submission)

        # Assert that no grace period deductions got handed out needlessly
        @grouping.reload
        @grouping.accepted_student_memberships.each do |student_membership|
          assert_equal members[student_membership.user.id], student_membership.user.remaining_grace_credits
        end

        # We should have all files except NotIncluded.java in the repository.
        assert_not_nil submission.submission_files.find_by_filename('TestFile.java')
        assert_not_nil submission.submission_files.find_by_filename('Test.java')
        assert_not_nil submission.submission_files.find_by_filename('Driver.java')
        assert_nil submission.submission_files.find_by_filename('OvertimeFile2.java')
        assert_nil submission.submission_files.find_by_filename('NotIncluded.java')
        assert_not_nil submission.get_latest_result
      end

    end

    context 'submit assignment 1 on time and submit assignment 2 before assignment 1 collection time' do
      setup do
        @assignment2 = Assignment.make
        @grouping2 = Grouping.make(assignment: @assignment2,
                                   group: @group)

        StudentMembership.make(grouping: @grouping2,
                               membership_status: 'inviter',
                               user: @student)
        grace_period_submission_rule = GracePeriodSubmissionRule.new
        @assignment2.replace_submission_rule(grace_period_submission_rule)
        GracePeriodDeduction.destroy_all

        grace_period_submission_rule.save

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

      # Regression test for issue 656.  The issue is when submitting files for an assignment before the grace period
      # of the previous assignment is over.  When calculating grace days for the previous assignment, it
      # takes the newer assignment submission as the submission time.  Therefore, grace days are being
      # taken off when it shouldn't have.
      should 'deduct 0 grace credits' do

        # The Student submits some files before the due date...
        submit_files_before_due_date

        # Now we're past the due date, but before the collection date, within the first
        # grace period.  Submit files for Assignment 2
        submit_files_for_assignment_after_due_before_collection(@assignment2, 'July 23 2009 9:00PM', 'NotIncluded.java', 'Not Included in Asssignment 1')

        # An Instructor or Grader decides to begin grading
        pretend_now_is(Time.parse('July 31 2009 1:00PM')) do
          members = {}
          @grouping.accepted_student_memberships.each do |student_membership|
            members[student_membership.user.id] = student_membership.user.remaining_grace_credits
          end
          submission = Submission.create_by_timestamp(@grouping, @assignment.submission_rule.calculate_collection_time)
          submission = @assignment.submission_rule.apply_submission_rule(submission)

          # Assert that each accepted member of this grouping did not get a GracePeriodDeduction
          @grouping.reload
          @grouping.accepted_student_memberships.each do |student_membership|
            assert_equal members[student_membership.user.id], student_membership.user.remaining_grace_credits
          end

          # We should have all files except OvertimeFile1.java and NotIncluded.java in the repository.
          assert_not_nil submission.submission_files.find_by_filename('TestFile.java')
          assert_not_nil submission.submission_files.find_by_filename('Test.java')
          assert_not_nil submission.submission_files.find_by_filename('Driver.java')
          assert_nil submission.submission_files.find_by_filename('OvertimeFile1.java')
          assert_nil submission.submission_files.find_by_filename('NotIncluded.java')
          assert_not_nil submission.get_latest_result
        end
      end

      # Regression test for issue 656.  The issue is when submitting files for an assignment before the grace period
      # of the previous assignment is over.  When calculating grace days for the previous assignment, it
      # takes the newer assignment submission as the submission time.  Therefore, grace days are being
      # taken off when it shouldn't have.
      should 'deduct 1 grace credits' do

        # The Student submits some files before the due date...
        submit_files_before_due_date

        # Now we're past the due date, but before the collection date, within the first
        # grace period.
        submit_files_after_due_date_before_collection_time('July 23 2009 9:00PM', 'OvertimeFile1.java', 'Some overtime contents')
        #Submit files for Assignment 2
        submit_files_for_assignment_after_due_before_collection(@assignment2, 'July 24 2009 9:00PM', 'NotIncluded.java', 'Not Included in Asssignment 1')

        # An Instructor or Grader decides to begin grading
        pretend_now_is(Time.parse('July 31 2009 1:00PM')) do
          members = {}
          @grouping.accepted_student_memberships.each do |student_membership|
            members[student_membership.user.id] = student_membership.user.remaining_grace_credits
          end
          submission = Submission.create_by_timestamp(@grouping, @assignment.submission_rule.calculate_collection_time)
          submission = @assignment.submission_rule.apply_submission_rule(submission)

          # Assert that each accepted member of this grouping did not get a GracePeriodDeduction
          @grouping.reload
          @grouping.accepted_student_memberships.each do |student_membership|
            assert_equal members[student_membership.user.id] -1, student_membership.user.remaining_grace_credits
          end

          # We should have all files except OvertimeFile1.java and NotIncluded.java in the repository.
          assert_not_nil submission.submission_files.find_by_filename('TestFile.java')
          assert_not_nil submission.submission_files.find_by_filename('Test.java')
          assert_not_nil submission.submission_files.find_by_filename('Driver.java')
          assert_not_nil submission.submission_files.find_by_filename('OvertimeFile1.java')
          assert_nil submission.submission_files.find_by_filename('NotIncluded.java')
          assert_not_nil submission.get_latest_result
        end
      end

    end
  end

  private

  def submit_files_before_due_date
    pretend_now_is(Time.parse('July 20 2009 5:00PM')) do
      assert Time.now < @assignment.due_date
      assert Time.now < @assignment.submission_rule.calculate_collection_time
      @group.access_repo do |repo|
        txn = repo.get_transaction('test')
        txn = add_file_helper(@assignment, txn, 'TestFile.java', 'Some contents for TestFile.java')
        txn = add_file_helper(@assignment, txn, 'Test.java', 'Some contents for Test.java')
        txn = add_file_helper(@assignment, txn, 'Driver.java', 'Some contents for Driver.java')
        repo.commit(txn)
      end
    end
  end

  def submit_files_after_due_date_before_collection_time(time, filename, text)
    pretend_now_is(Time.parse(time)) do
      assert Time.now > @assignment.due_date
      assert Time.now < @assignment.submission_rule.calculate_collection_time
      @group.access_repo do |repo|
        txn = repo.get_transaction('test')
        txn = add_file_helper(@assignment, txn, filename, text)
        repo.commit(txn)
      end
    end
  end

  def submit_files_after_due_date_after_collection_time(time, filename, text)
    pretend_now_is(Time.parse(time)) do
      assert Time.now > @assignment.due_date
      assert Time.now > @assignment.submission_rule.calculate_collection_time
      @group.access_repo do |repo|
        txn = repo.get_transaction('test')
        txn = add_file_helper(@assignment, txn, filename, text)
        repo.commit(txn)
      end
    end
  end

  # Submit files after the due date of the past assignment but before its collection time
  def submit_files_for_assignment_after_due_before_collection(assignment, time, filename, text)
    pretend_now_is(Time.parse(time)) do
      assert Time.now < assignment.due_date
      assert Time.now < assignment.submission_rule.calculate_collection_time
      @group.access_repo do |repo|
        txn = repo.get_transaction('test1')
        txn = add_file_helper(assignment, txn, filename, text)
        repo.commit(txn)
      end
    end
  end

  def add_file_helper(assignment, txn, file_name, file_contents)
    path = File.join(assignment.repository_folder, file_name)
    txn.add(path, file_contents, '')
    txn
  end


  def add_period_helper(submission_rule, hours)
    period = Period.new
    period.submission_rule = submission_rule
    period.hours = hours
    period.save
  end

end
