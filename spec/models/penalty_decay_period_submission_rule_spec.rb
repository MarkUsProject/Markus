describe PenaltyDecayPeriodSubmissionRule do

  it 'be able to create PenaltyDecayPeriodSubmissionRule' do
    rule = PenaltyDecayPeriodSubmissionRule.new
    rule.assignment = create(:assignment)
    expect(rule.save).to be_truthy
  end

  context 'A section with penalty_decay_period_submission rules.' do

    before :each do
      @group = create(:group)
      @grouping = create(:grouping, group: @group)
      @membership = create(:student_membership, grouping: @grouping, membership_status: StudentMembership::STATUSES[:inviter])
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

    it 'be able to calculate collection time' do
      expect(Time.now).to be < @assignment.submission_rule.calculate_collection_time
    end

    it 'be able to calculate collection time for a grouping' do
      expect(Time.now).to be < @assignment.due_date
      due_date_plus_period = @assignment.due_date + 48.hours
      expect(due_date_plus_period.to_a).to eq @rule.calculate_grouping_collection_time(@membership.grouping).to_a
    end

    it 'not apply decay period deductions for on-time submissions' do
      # Student hands in some files on time.
      pretend_now_is(Time.now + 1.days) do
        expect(Time.now).to be < @assignment.due_date
        expect(Time.now).to be < @assignment.submission_rule.calculate_collection_time
        expect(Time.now).to be < @assignment.submission_rule.calculate_grouping_collection_time(@membership.grouping)

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
        expect(result).not_to be_nil
        expect(result.extra_marks).to be_empty
        expect(result.get_total_extra_percentage).to eq 0

        # We should have collected all files in the repository.
        expect(submission.submission_files.find_by_filename('TestFile.java')).not_to be_nil
        expect(submission.submission_files.find_by_filename('Test.java')).not_to be_nil
        expect(submission.submission_files.find_by_filename('Driver.java')).not_to be_nil
      end
    end

    it 'add a 10% penalty to the submission result' do
      # The Student submits some files before the due date...
      pretend_now_is(Time.now + 1.days) do
        expect(Time.now).to be < @assignment.due_date
        expect(Time.now).to be < @assignment.submission_rule.calculate_collection_time
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
        expect(Time.now).to be > @assignment.due_date
        expect(Time.now).to be < @assignment.submission_rule.calculate_collection_time
        @group.access_repo do |repo|
          txn = repo.get_transaction('test')
          txn = add_file_helper(txn, 'OvertimeFile.java', 'Some overtime contents')
          repo.commit(txn)
        end
      end

      # Now we're past the collection date.
      pretend_now_is(Time.now + 5.days) do
        expect(Time.now).to be > @assignment.due_date
        expect(Time.now).to be > @assignment.submission_rule.calculate_collection_time
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
        expect(result).not_to be_nil
        # We expect only a single extra mark is attached
        expect(result.get_total_extra_percentage).to eq -10
        expect(result.extra_marks.size).to eq 1
        penalty = result.extra_marks.first
        expect(penalty.unit).not_to be_nil
        expect(penalty.extra_mark).to eq -10
        expect(penalty.unit).to eq ExtraMark::PERCENTAGE

        # We should have all files except NotIncluded.java in the repository.
        expect(submission.submission_files.find_by_filename('TestFile.java')).not_to be_nil
        expect(submission.submission_files.find_by_filename('Test.java')).not_to be_nil
        expect(submission.submission_files.find_by_filename('Driver.java')).not_to be_nil
        expect(submission.submission_files.find_by_filename('OvertimeFile.java')).not_to be_nil
        expect(submission.submission_files.find_by_filename('NotIncluded.java')).to be_nil
        expect(submission.get_latest_result).not_to be_nil
      end
    end

    it 'add 30% penalty to submission' do
      # The Student submits some files before the due date...
      pretend_now_is(Time.now + 1.days) do
        expect(Time.now).to be < @assignment.due_date
        expect(Time.now).to be < @assignment.submission_rule.calculate_collection_time
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
        expect(Time.now).to be > @assignment.due_date
        expect(Time.now).to be < @assignment.submission_rule.calculate_collection_time
        @group.access_repo do |repo|
          txn = repo.get_transaction('test')
          txn = add_file_helper(txn, 'OvertimeFile1.java', 'Some overtime contents')
          repo.commit(txn)
        end
      end

      # Now we're past the due date, but before the collection date, within the penalty period.
      pretend_now_is(Time.now + 3.days + 1.hours) do
        expect(Time.now).to be > @assignment.due_date
        expect(Time.now).to be < @assignment.submission_rule.calculate_collection_time
        @group.access_repo do |repo|
          txn = repo.get_transaction('test')
          txn = add_file_helper(txn, 'OvertimeFile2.java', 'Some overtime contents')
          repo.commit(txn)
        end
      end

      # Now we're past the collection date.
      pretend_now_is(Time.now + 4.days + 1.hours) do
        expect(Time.now).to be > @assignment.due_date
        expect(Time.now).to be > @assignment.submission_rule.calculate_collection_time
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
        expect(result).not_to be_nil
        # We expect only a single extra mark is attached
        expect(result.get_total_extra_percentage).to eq -30
        expect(result.extra_marks.size).to eq 1
        penalty = result.extra_marks.first
        expect(penalty.unit).not_to be_nil
        expect(penalty.extra_mark).to eq -30
        expect(penalty.unit).to eq ExtraMark::PERCENTAGE

        # We should have all files except NotIncluded.java in the repository.
        expect(submission.submission_files.find_by_filename('TestFile.java')).not_to be_nil
        expect(submission.submission_files.find_by_filename('Test.java')).not_to be_nil
        expect(submission.submission_files.find_by_filename('Driver.java')).not_to be_nil
        expect(submission.submission_files.find_by_filename('OvertimeFile1.java')).not_to be_nil
        expect(submission.submission_files.find_by_filename('OvertimeFile2.java')).not_to be_nil
        expect(submission.submission_files.find_by_filename('NotIncluded.java')).to be_nil
        expect(submission.get_latest_result).not_to be_nil
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
