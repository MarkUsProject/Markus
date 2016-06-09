require File.expand_path(File.join(File.dirname(__FILE__), '..', 'test_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'blueprints', 'helper'))

require 'shoulda'
require 'time-warp'

class PenaltyPeriodSubmissionRuleTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  context 'Assignment has a single grace period of 24 hours after due date' do
    setup do
      @assignment = Assignment.make
      @group = Group.make
      @grouping = Grouping.make(assignment: @assignment,
                                group: @group)
      StudentMembership.make(grouping: @grouping,
                             membership_status: 'inviter')
      penalty_period_submission_rule = PenaltyPeriodSubmissionRule.new
      @assignment.replace_submission_rule(penalty_period_submission_rule)
      penalty_period_submission_rule.save

      # On July 1 at 1PM, the instructor sets up the course...
      pretend_now_is(Time.parse('July 1 2009 1:00PM')) do
        # Due date is July 23 @ 5PM
        @assignment.due_date = Time.parse('July 23 2009 5:00PM')
        # Add two 24 hour penalty periods, each with a 10% penalty
        # Overtime begins at July 23 @ 5PM
        add_period_helper(@assignment.submission_rule, 24, 10)
        add_period_helper(@assignment.submission_rule, 24, 10)
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

    should 'not add any penalty to the submission result' do
      pretend_now_is(Time.parse('July 20 2009 5:00PM')) do
        assert Time.now < @assignment.due_date
        assert Time.now < @assignment.submission_rule.calculate_collection_time
        assert Time.now < @assignment.submission_rule.calculate_grouping_collection_time(@grouping)
        @group.access_repo do |repo|
          txn = repo.get_transaction('test')
          txn = add_file_helper(txn, 'TestFile.java', 'Some contents for TestFile.java')
          txn = add_file_helper(txn, 'Test.java', 'Some contents for Test.java')
          txn = add_file_helper(txn, 'Driver.java', 'Some contents for Driver.java')
          repo.commit(txn)
        end
      end
      # An Instructor or Grader decides to begin grading
      pretend_now_is(Time.parse('July 28 2009 1:00PM')) do
        submission = Submission.create_by_timestamp(@grouping, @assignment.submission_rule.calculate_collection_time)
        submission = @assignment.submission_rule.apply_submission_rule(submission)

        # Assert that this submission did not get a penalty
        result = submission.get_latest_result
        assert_not_nil result
        assert result.extra_marks.empty?
        assert_equal 0, result.get_total_extra_percentage

        # We should have collected all files in the repository.
        assert_not_nil submission.submission_files.find_by_filename('TestFile.java')
        assert_not_nil submission.submission_files.find_by_filename('Test.java')
        assert_not_nil submission.submission_files.find_by_filename('Driver.java')
      end

    end

    should 'add a 10% penalty to the submission result' do
      # The Student submits some files before the due date...

      pretend_now_is(Time.parse('July 20 2009 5:00PM')) do
        assert Time.now < @assignment.due_date
        assert Time.now < @assignment.submission_rule.calculate_collection_time
        @group.access_repo do |repo|
          txn = repo.get_transaction('test')
          txn = add_file_helper(txn, 'TestFile.java', 'Some contents for TestFile.java')
          txn = add_file_helper(txn, 'Test.java', 'Some contents for Test.java')
          txn = add_file_helper(txn, 'Driver.java', 'Some contents for Driver.java')
          repo.commit(txn)
        end
      end

      # Now we're past the due date, but before the collection date.
      pretend_now_is(Time.parse('July 23 2009 9:00PM')) do
        assert Time.now > @assignment.due_date
        assert Time.now < @assignment.submission_rule.calculate_collection_time
        @group.access_repo do |repo|
          txn = repo.get_transaction('test')
          txn = add_file_helper(txn, 'OvertimeFile.java', 'Some overtime contents')
          repo.commit(txn)
        end
      end

      # Now we're past the collection date.
      pretend_now_is(Time.parse('July 25 2009 10:00PM')) do
        assert Time.now > @assignment.due_date
        assert Time.now > @assignment.submission_rule.calculate_collection_time
        @group.access_repo do |repo|
          txn = repo.get_transaction('test')
          txn = add_file_helper(txn, 'NotIncluded.java', 'Should not be included in grading')
          repo.commit(txn)
        end
      end

      # An Instructor or Grader decides to begin grading
      pretend_now_is(Time.parse('July 28 2009 1:00PM')) do
        submission = Submission.create_by_timestamp(@grouping, @assignment.submission_rule.calculate_collection_time)
        submission = @assignment.submission_rule.apply_submission_rule(submission)

        # Assert that this submission got a penalty
        result = submission.get_latest_result
        assert_not_nil result
        # We expect only a single extra mark is attached
        assert_equal -10, result.get_total_extra_percentage
        assert_equal 1, result.extra_marks.size
        penalty = result.extra_marks.first
        assert_not_nil penalty.unit
        assert_equal -10, penalty.extra_mark
        assert_equal ExtraMark::PERCENTAGE, penalty.unit

        # We should have all files except NotIncluded.java in the repository.
        assert_not_nil submission.submission_files.find_by_filename('TestFile.java')
        assert_not_nil submission.submission_files.find_by_filename('Test.java')
        assert_not_nil submission.submission_files.find_by_filename('Driver.java')
        assert_not_nil submission.submission_files.find_by_filename('OvertimeFile.java')
        assert_nil submission.submission_files.find_by_filename('NotIncluded.java')
        assert_not_nil submission.get_latest_result
      end

    end

    should 'add 20% penalty to submission' do
      # The Student submits some files before the due date...
      pretend_now_is(Time.parse('July 20 2009 5:00PM')) do
        assert Time.now < @assignment.due_date
        assert Time.now < @assignment.submission_rule.calculate_collection_time
        @group.access_repo do |repo|
          txn = repo.get_transaction('test')
          txn = add_file_helper(txn, 'TestFile.java', 'Some contents for TestFile.java')
          txn = add_file_helper(txn, 'Test.java', 'Some contents for Test.java')
          txn = add_file_helper(txn, 'Driver.java', 'Some contents for Driver.java')
          repo.commit(txn)
        end
      end

      # Now we're past the due date, but before the collection date, within the first
      # grace period
      pretend_now_is(Time.parse('July 23 2009 9:00PM')) do
        assert Time.now > @assignment.due_date
        assert Time.now < @assignment.submission_rule.calculate_collection_time
        @group.access_repo do |repo|
          txn = repo.get_transaction('test')
          txn = add_file_helper(txn, 'OvertimeFile1.java', 'Some overtime contents')
          repo.commit(txn)
        end
      end

      # Now we're past the due date, but before the collection date, within the second
      # grace period
      pretend_now_is(Time.parse('July 24 2009 9:00PM')) do
        assert Time.now > @assignment.due_date
        assert Time.now < @assignment.submission_rule.calculate_collection_time
        @group.access_repo do |repo|
          txn = repo.get_transaction('test')
          txn = add_file_helper(txn, 'OvertimeFile2.java', 'Some overtime contents')
          repo.commit(txn)
        end
      end

      # Now we're past the collection date.
      pretend_now_is(Time.parse('July 25 2009 10:00PM')) do
        assert Time.now > @assignment.due_date
        assert Time.now > @assignment.submission_rule.calculate_collection_time
        @group.access_repo do |repo|
          txn = repo.get_transaction('test')
          txn = add_file_helper(txn, 'NotIncluded.java', 'Should not be included in grading')
          repo.commit(txn)
        end
      end

      # An Instructor or Grader decides to begin grading
      pretend_now_is(Time.parse('July 28 2009 1:00PM')) do
        submission = Submission.create_by_timestamp(@grouping, @assignment.submission_rule.calculate_collection_time)
        submission = @assignment.submission_rule.apply_submission_rule(submission)

        # Assert that this submission got a penalty
        result = submission.get_latest_result
        assert_not_nil result
        # We expect only a single extra mark is attached
        assert_equal -20, result.get_total_extra_percentage
        assert_equal 1, result.extra_marks.size
        penalty = result.extra_marks.first
        assert_not_nil penalty.unit
        assert_equal -20, penalty.extra_mark
        assert_equal ExtraMark::PERCENTAGE, penalty.unit


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

  private

  def add_file_helper(txn, file_name, file_contents)
    path = File.join(@assignment.repository_folder, file_name)
    txn.add(path, file_contents, '')
    txn
  end

  def add_period_helper(submission_rule, hours, deduction_amount)
    period = Period.new
    period.submission_rule = submission_rule
    period.hours = hours
    period.deduction = deduction_amount
    period.save
  end


end
