require 'test_helper'
require 'shoulda'

class GracePeriodSubmissionRuleTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  
  context "Assignment has a single grace period of 24 hours after due date" do
    setup do
      @group = groups(:group_1)
      @grouping = groupings(:grouping_1)
      @assignment = @grouping.assignment

      # On July 1 at 1PM, the instructor sets up the course...
      pretend_now_is(Time.parse("July 1 2009 1:00PM")) do
        # Due date is July 23 @ 5PM
        @assignment.due_date = Time.parse("July 23 2009 5:00PM")
        # Add two 24 hour grace periods
        # Overtime begins at July 23 @ 5PM
        add_period_helper(@assignment.submission_rule, 24)
        add_period_helper(@assignment.submission_rule, 24)
        # Collect date is now after July 25 @ 5PM
        @assignment.save

        @group.build_repository
      end
      # On July 15, the Student logs in, triggering repository folder
      # creation
      pretend_now_is(Time.parse("July 15 2009 6:00PM")) do
        @grouping.create_grouping_repository_folder
      end
    end
    
    teardown do
      Repository.get_class(REPOSITORY_TYPE).purge_all
    end
  
    should "deduct a single grace credit" do
      # The Student submits some files before the due date...

      pretend_now_is(Time.parse("July 20 2009 5:00PM")) do
        assert Time.now < @assignment.due_date
        assert Time.now < @assignment.submission_rule.calculate_collection_time
        repo = @group.repo
        txn = repo.get_transaction("test")
        txn = add_file_helper(txn, 'TestFile.java', 'Some contents for TestFile.java')
        txn = add_file_helper(txn, 'Test.java', 'Some contents for Test.java')
        txn = add_file_helper(txn, 'Driver.java', 'Some contents for Driver.java')        
        repo.commit(txn)
      end
      
      # Now we're past the due date, but before the collection date.
      pretend_now_is(Time.parse("July 23 2009 9:00PM")) do
        assert Time.now > @assignment.due_date
        assert Time.now < @assignment.submission_rule.calculate_collection_time
        repo = @group.repo
        txn = repo.get_transaction("test")
        txn = add_file_helper(txn, "OvertimeFile.java", "Some overtime contents")
        repo.commit(txn)
      end
      
      # Now we're past the collection date.
      pretend_now_is(Time.parse("July 25 2009 10:00PM")) do
        assert Time.now > @assignment.due_date
        assert Time.now > @assignment.submission_rule.calculate_collection_time
        repo = @group.repo
        txn = repo.get_transaction("test")
        txn = add_file_helper(txn, "NotIncluded.java", "Should not be included in grading")
        repo.commit(txn)
      end
      
      # An Instructor or Grader decides to begin grading
      pretend_now_is(Time.parse("July 28 2009 1:00PM")) do
        members = {}
        @grouping.accepted_student_memberships.each do |student_membership|
          members[student_membership.user.id] = student_membership.user.remaining_grace_credits
        end
        submission = Submission.create_by_timestamp(@grouping, @assignment.submission_rule.calculate_collection_time)
        submission = @assignment.submission_rule.apply_submission_rule(submission)
        
        # Assert that each accepted member of this grouping got a GracePeriodDeduction
        @grouping.accepted_student_memberships.each do |student_membership|
          assert_equal members[student_membership.user.id] - 1, student_membership.user.remaining_grace_credits
        end
        
        # We should have all files except NotIncluded.java in the repository.  
        assert_not_nil submission.submission_files.find_by_filename("TestFile.java")
        assert_not_nil submission.submission_files.find_by_filename("Test.java")
        assert_not_nil submission.submission_files.find_by_filename("Driver.java")
        assert_not_nil submission.submission_files.find_by_filename("OvertimeFile.java")
        assert_nil submission.submission_files.find_by_filename("NotIncluded.java")
        assert_not_nil submission.result
      end

    end
  
    should "deduct 2 grace credits" do
      # The Student submits some files before the due date...

      pretend_now_is(Time.parse("July 20 2009 5:00PM")) do
        assert Time.now < @assignment.due_date
        assert Time.now < @assignment.submission_rule.calculate_collection_time
        repo = @group.repo
        txn = repo.get_transaction("test")
        txn = add_file_helper(txn, 'TestFile.java', 'Some contents for TestFile.java')
        txn = add_file_helper(txn, 'Test.java', 'Some contents for Test.java')
        txn = add_file_helper(txn, 'Driver.java', 'Some contents for Driver.java')        
        repo.commit(txn)
      end
      
      # Now we're past the due date, but before the collection date, within the first
      # grace period
      pretend_now_is(Time.parse("July 23 2009 9:00PM")) do
        assert Time.now > @assignment.due_date
        assert Time.now < @assignment.submission_rule.calculate_collection_time
        repo = @group.repo
        txn = repo.get_transaction("test")
        txn = add_file_helper(txn, "OvertimeFile1.java", "Some overtime contents")
        repo.commit(txn)
      end

      # Now we're past the due date, but before the collection date, within the second
      # grace period
      pretend_now_is(Time.parse("July 24 2009 9:00PM")) do
        assert Time.now > @assignment.due_date
        assert Time.now < @assignment.submission_rule.calculate_collection_time
        repo = @group.repo
        txn = repo.get_transaction("test")
        txn = add_file_helper(txn, "OvertimeFile2.java", "Some overtime contents")
        repo.commit(txn)
      end
      
      # Now we're past the collection date.
      pretend_now_is(Time.parse("July 25 2009 10:00PM")) do
        assert Time.now > @assignment.due_date
        assert Time.now > @assignment.submission_rule.calculate_collection_time
        repo = @group.repo
        txn = repo.get_transaction("test")
        txn = add_file_helper(txn, "NotIncluded.java", "Should not be included in grading")
        repo.commit(txn)
      end
      
      # An Instructor or Grader decides to begin grading
      pretend_now_is(Time.parse("July 28 2009 1:00PM")) do
        members = {}
        @grouping.accepted_student_memberships.each do |student_membership|
          members[student_membership.user.id] = student_membership.user.remaining_grace_credits
        end
        submission = Submission.create_by_timestamp(@grouping, @assignment.submission_rule.calculate_collection_time)
        submission = @assignment.submission_rule.apply_submission_rule(submission)
        
        # Assert that each accepted member of this grouping got a GracePeriodDeduction
        @grouping.accepted_student_memberships.each do |student_membership|
          assert_equal members[student_membership.user.id] - 2, student_membership.user.remaining_grace_credits
        end

        # We should have all files except NotIncluded.java in the repository.  
        assert_not_nil submission.submission_files.find_by_filename("TestFile.java")
        assert_not_nil submission.submission_files.find_by_filename("Test.java")
        assert_not_nil submission.submission_files.find_by_filename("Driver.java")
        assert_not_nil submission.submission_files.find_by_filename("OvertimeFile1.java")
        assert_not_nil submission.submission_files.find_by_filename("OvertimeFile2.java")
        assert_nil submission.submission_files.find_by_filename("NotIncluded.java")
        assert_not_nil submission.result
            
      end

    end


    should "not deduct grace credits because there aren't enough of them" do
    
      # Set it up so that a member of this Grouping has only 1 grace credit left
      student = @grouping.accepted_student_memberships.first.user
      student.grace_credits = 1
      student.save
      
      # There should now only be 1 grace credit available for this grouping
      assert_equal 1, @grouping.available_grace_credits
      
      # The Student submits some files before the due date...
      pretend_now_is(Time.parse("July 20 2009 5:00PM")) do
        assert Time.now < @assignment.due_date
        assert Time.now < @assignment.submission_rule.calculate_collection_time
        repo = @group.repo
        txn = repo.get_transaction("test")
        txn = add_file_helper(txn, 'TestFile.java', 'Some contents for TestFile.java')
        txn = add_file_helper(txn, 'Test.java', 'Some contents for Test.java')
        txn = add_file_helper(txn, 'Driver.java', 'Some contents for Driver.java')        
        repo.commit(txn)
      end
      
      # Now we're past the due date, but before the collection date, within the second
      # grace period.  Because one of the students in the Grouping only has one grace credit,
      #  OvertimeFile2.java shouldn't be accepted into grading.
      pretend_now_is(Time.parse("July 24 2009 9:00PM")) do
        assert Time.now > @assignment.due_date
        assert Time.now < @assignment.submission_rule.calculate_collection_time
        repo = @group.repo
        txn = repo.get_transaction("test")
        txn = add_file_helper(txn, "OvertimeFile2.java", "Some overtime contents")
        repo.commit(txn)
      end
      
      # Now we're past the collection date.
      pretend_now_is(Time.parse("July 25 2009 10:00PM")) do
        assert Time.now > @assignment.due_date
        assert Time.now > @assignment.submission_rule.calculate_collection_time
        repo = @group.repo
        txn = repo.get_transaction("test")
        txn = add_file_helper(txn, "NotIncluded.java", "Should not be included in grading")
        repo.commit(txn)
      end
      
      # An Instructor or Grader decides to begin grading
      pretend_now_is(Time.parse("July 28 2009 1:00PM")) do
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
        assert_not_nil submission.submission_files.find_by_filename("TestFile.java")
        assert_not_nil submission.submission_files.find_by_filename("Test.java")
        assert_not_nil submission.submission_files.find_by_filename("Driver.java")
        assert_nil submission.submission_files.find_by_filename("OvertimeFile2.java")
        assert_nil submission.submission_files.find_by_filename("NotIncluded.java")
        assert_not_nil submission.result
      end

    end
    
  end
  
  private 
  
  def add_file_helper(txn, file_name, file_contents)
    path = File.join(@assignment.repository_folder, file_name)
    txn.add(path, file_contents, '')
    return txn
  end
  
  def add_period_helper(submission_rule, hours)
    period = Period.new
    period.submission_rule = submission_rule
    period.hours = hours
    period.save
  end
  
  
end
