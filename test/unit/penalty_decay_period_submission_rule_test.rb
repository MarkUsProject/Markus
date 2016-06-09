require File.expand_path(File.join(File.dirname(__FILE__), '..', 'test_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'blueprints', 'helper'))
require 'shoulda'
require 'time-warp'
require 'machinist'

class PenaltyDecayPeriodSubmissionRuleTest < ActiveSupport::TestCase

  should 'be able to create PenaltyDecayPeriodSubmissionRule' do
    rule = PenaltyDecayPeriodSubmissionRule.new
    rule.assignment = Assignment.make
    assert rule.save
  end

  context 'A section with penalty_decay_period_submission rules.' do

    setup do
      @group = Group.make
      @grouping = Grouping.make(group: @group)
      @membership = StudentMembership.make(grouping: @grouping, membership_status: StudentMembership::STATUSES[:inviter])
      @assignment = @grouping.assignment
      @rule = PenaltyDecayPeriodSubmissionRule.new
      @assignment.replace_submission_rule(@rule)
      PenaltyDecayPeriodSubmissionRule.destroy_all
      @rule.save

      # An Instructor sets up a course.
      @assignment.due_date = Time.now + 2.days

      # Add two 24 hour penalty decay periods
      # Overtime begins in two days.
      add_period_helper(@assignment.submission_rule,24,10,12)
      add_period_helper(@assignment.submission_rule,24,10,12)
      # Collection date is in 4 days.
      @assignment.save

      @grouping.create_grouping_repository_folder
    end

    teardown do
      destroy_repos
    end

    should 'be able to calculate collection time' do
      assert Time.now < @assignment.submission_rule.calculate_collection_time
    end

    should 'be able to calculate collection time for a grouping' do
      assert Time.now <  @assignment.due_date
      assert_equal @assignment.due_date.to_a, @rule.calculate_grouping_collection_time(@membership.grouping).to_a
    end

    should 'not apply decay period deductions for on-time submissions' do
      # Student hands in some files on time.
      pretend_now_is(Time.now + 1.days) do
        assert Time.now < @assignment.due_date
        assert Time.now < @assignment.submission_rule.calculate_collection_time
        assert Time.now < @assignment.submission_rule.calculate_grouping_collection_time(@membership.grouping)

        @group.access_repo do |repo|
          txn = repo.get_transaction('test')
          txn = add_file_helper(txn, 'TestFile.java', 'Some contents for TestFile.java')
          txn = add_file_helper(txn, 'Test.java', 'Some contents for Test.java')
          txn = add_file_helper(txn, 'Driver.java', 'Some contents for Driver.java')
          repo.commit(txn)
        end
      end

      # An instructor begins grading
      pretend_now_is(Time.now + 7.days) do
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
      pretend_now_is(Time.now + 1.days) do
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
      pretend_now_is(Time.now + 2.days + 1.hour) do
        assert Time.now > @assignment.due_date
        assert Time.now < @assignment.submission_rule.calculate_collection_time
        @group.access_repo do |repo|
          txn = repo.get_transaction('test')
          txn = add_file_helper(txn, 'OvertimeFile.java', 'Some overtime contents')
          repo.commit(txn)
        end
      end

      # Now we're past the collection date.
      pretend_now_is(Time.now + 5.days) do
        assert Time.now > @assignment.due_date
        assert Time.now > @assignment.submission_rule.calculate_collection_time
        @group.access_repo do |repo|
          txn = repo.get_transaction('test')
          txn = add_file_helper(txn, 'NotIncluded.java', 'Should not be included in grading')
          repo.commit(txn)
        end
      end

      # An Instructor or Grader decides to begin grading
      pretend_now_is(Time.now + 5.days + 1.hours) do
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

    should 'add 30% penalty to submission' do
      # The Student submits some files before the due date...
      pretend_now_is(Time.now + 1.days) do
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

      # Now we are past the due date, but before the collection date, within the first penalty period
      pretend_now_is(Time.now + 2.days + 1.hours) do
        assert Time.now > @assignment.due_date
        assert Time.now < @assignment.submission_rule.calculate_collection_time
        @group.access_repo do |repo|
          txn = repo.get_transaction('test')
          txn = add_file_helper(txn, 'OvertimeFile1.java', 'Some overtime contents')
          repo.commit(txn)
        end
      end

      # Now we're past the due date, but before the collection date, within the penalty period.
      pretend_now_is(Time.now + 3.days + 1.hours) do
        assert Time.now > @assignment.due_date
        assert Time.now < @assignment.submission_rule.calculate_collection_time
        @group.access_repo do |repo|
          txn = repo.get_transaction('test')
          txn = add_file_helper(txn, 'OvertimeFile2.java', 'Some overtime contents')
          repo.commit(txn)
        end
      end

      # Now we're past the collection date.
      pretend_now_is(Time.now + 4.days + 1.hours) do
        assert Time.now > @assignment.due_date
        assert Time.now > @assignment.submission_rule.calculate_collection_time
        @group.access_repo do |repo|
          txn = repo.get_transaction('test')
          txn = add_file_helper(txn, 'NotIncluded.java', 'Should not be included in grading')
          repo.commit(txn)
        end
      end

      # An Instructor or Grader decides to begin grading
      pretend_now_is(Time.now + 5.days) do
        submission = Submission.create_by_timestamp(@grouping, @assignment.submission_rule.calculate_collection_time)
        submission = @assignment.submission_rule.apply_submission_rule(submission)

        # Assert that this submission got a penalty
        result = submission.get_latest_result
        assert_not_nil result
        # We expect only a single extra mark is attached
        assert_equal -30, result.get_total_extra_percentage
        assert_equal 1, result.extra_marks.size
        penalty = result.extra_marks.first
        assert_not_nil penalty.unit
        assert_equal -30, penalty.extra_mark
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

  end #context

  private

  def add_file_helper(txn, file_name, file_contents)
    path = File.join(@assignment.repository_folder, file_name)
    txn.add(path, file_contents, '')
    return txn
  end

  def add_period_helper(submission_rule, hours, deduction_amount, interval)
    period = Period.new
    period.submission_rule = submission_rule
    period.hours = hours
    period.deduction = deduction_amount
    period.interval = interval
    period.save
  end

end
