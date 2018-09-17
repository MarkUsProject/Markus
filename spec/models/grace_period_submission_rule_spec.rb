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
      @membership = create(:student_membership, grouping: @grouping, membership_status: StudentMembership::STATUSES[:inviter])
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

    it 'be able to calculate collection time' do
      expect(Time.now).to be > @assignment.submission_rule.calculate_collection_time
    end

    it 'be able to calculate collection time for a grouping' do
      expect(Time.now).to be > @assignment.due_date
      expect(@assignment.due_date.to_a).to eq @rule.calculate_grouping_collection_time(@membership.grouping).to_a
    end

    it 'does not deduct credit for on time submission' do
      # The Student submits their files before the due date
      submit_files_before_due_date

      # An Instructor or Grader decides to begin grading
      pretend_now_is(Time.parse('July 28 2009 1:00PM')) do
        members = {}
        @grouping.accepted_student_memberships.each do |student_membership|
          members[student_membership.user.id] = student_membership.user.remaining_grace_credits
        end
        submission = Submission.create_by_timestamp(@grouping, @assignment.submission_rule.calculate_collection_time)
        submission = @assignment.submission_rule.apply_submission_rule(submission)

        # Assert that each accepted member of this grouping did not get a GracePeriodDeduction
        @grouping.reload
        @grouping.accepted_student_memberships.each do |student_membership|
          expect(members[student_membership.user.id]).to eq(student_membership.user.remaining_grace_credits)
        end

        # We should have all files except NotIncluded.java in the repository.
        expect(submission.submission_files.find_by_filename('TestFile.java')).not_to be_nil
        expect(submission.submission_files.find_by_filename('Test.java')).not_to be_nil
        expect(submission.submission_files.find_by_filename('Driver.java')).not_to be_nil
        expect(submission.submission_files.find_by_filename('NotIncluded.java')).to be_nil
        expect(submission.get_latest_result).not_to be_nil
      end
    end

    it 'deducts a single grace period credit' do
      # The Student submits some files before the due date...
      submit_files_before_due_date

      # Now we're past the due date, but before the collection date.
      submit_files_after_due_date_before_collection_time('July 23 2009 9:00PM', 'OvertimeFile.java', 'Some overtime contents')

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
          expect(student_membership.user.remaining_grace_credits).to eq(members[student_membership.user.id] - 1)
        end

        # We should have all files except NotIncluded.java in the repository.
        expect(submission.submission_files.find_by_filename('TestFile.java')).not_to be_nil
        expect(submission.submission_files.find_by_filename('Test.java')).not_to be_nil
        expect(submission.submission_files.find_by_filename('Driver.java')).not_to be_nil
        expect(submission.submission_files.find_by_filename('OvertimeFile.java')).not_to be_nil
        expect(submission.submission_files.find_by_filename('NotIncluded.java')).to be_nil
        expect(submission.get_latest_result).not_to be_nil
      end
    end

    it 'deducts 2 grace credits' do
      # The Student submits some files before the due date...
      submit_files_before_due_date

      # Now we're past the due date, but before the collection date, within the first grace period
      submit_files_after_due_date_before_collection_time('July 23 2009 9:00PM', 'OvertimeFile1.java', 'Some overtime contents')

      # Now we're past the due date, but before the collection date, within the second grace period
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

        # Assert that each accepted member of this grouping got 2 GracePeriodDeduction
        @grouping.reload
        @grouping.accepted_student_memberships.each do |student_membership|
          expect(student_membership.user.remaining_grace_credits).to eq(members[student_membership.user.id] - 2)
        end

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

    context '2 grace credits deduction are in the database for assignment' do

      before :each do
        @grouping.accepted_student_memberships.each do |student_membership|
          deduction = GracePeriodDeduction.new
          deduction.membership = student_membership
          deduction.deduction = 2
          deduction.save
        end
      end

      it 'deducts 1 grace credits' do

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
            # The students should have 4 grace credits remaining from their 5 grace credits
            expect(student_membership.user.remaining_grace_credits).to eq(4)
          end

          # We should have all files except NotIncluded.java in the repository.
          expect(submission.submission_files.find_by_filename('TestFile.java')).not_to be_nil
          expect(submission.submission_files.find_by_filename('Test.java')).not_to be_nil
          expect(submission.submission_files.find_by_filename('Driver.java')).not_to be_nil
          expect(submission.submission_files.find_by_filename('OvertimeFile1.java')).not_to be_nil
          expect(submission.submission_files.find_by_filename('NotIncluded.java')).to be_nil
          expect(submission.get_latest_result).not_to be_nil
        end
      end

      it 'deducts 2 grace credits' do
        # The Student submits some files before the due date...
        submit_files_before_due_date

        # Now we're past the due date, but before the collection date, within the first grace period
        submit_files_after_due_date_before_collection_time('July 23 2009 9:00PM', 'OvertimeFile1.java', 'Some overtime contents')

        # Now we're past the due date, but before the collection date, within the second grace period
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
            # The students should have 3 grace credits remaining from their 5 grace credits
            expect(student_membership.user.remaining_grace_credits).to eq(3)
          end

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

      it "does not deduct grace credits because there aren't enough of them (1 grace credit left)" do
        # Set it up so that a member of this Grouping has only 1 (3 grace credits - 2 deductions) grace credit left
        student = @grouping.accepted_student_memberships.first.user
        student.grace_credits = 3
        student.save

        # There should now only be 1 grace credit available for this grouping CHECK THIS
        expect(@grouping.available_grace_credits).to eq(1)

        # The Student submits some files before the due date...
        submit_files_before_due_date

        # Now we're past the due date, but before the collection date, within the second grace period.
        # Because one of the students in the Grouping only has one grace credit,
        # OvertimeFile2.java shouldn't be accepted into grading.
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

          # Assert that each accepted member of this grouping did not get a GracePeriodDeduction
          @grouping.accepted_student_memberships.each do |student_membership|
            expect(student_membership.user.remaining_grace_credits).to eq(members[student_membership.user.id])
          end

          # We should have all files except NotIncluded.java in the repository.
          expect(submission.submission_files.find_by_filename('TestFile.java')).not_to be_nil
          expect(submission.submission_files.find_by_filename('Test.java')).not_to be_nil
          expect(submission.submission_files.find_by_filename('Driver.java')).not_to be_nil
          expect(submission.submission_files.find_by_filename('OvertimeFile2.java')).not_to be_nil
          expect(submission.submission_files.find_by_filename('NotIncluded.java')).to be_nil
          expect(submission.get_latest_result).not_to be_nil
        end
      end

      it "does not deduct grace credits because there aren't any of them (0 grace credit left)" do

        # Set it up so that a member of this Grouping has no grace credits
        student = @grouping.accepted_student_memberships.first.user
        student.grace_credits = 2
        student.save

        # There should now only be 0 grace credit available for this grouping
        expect(@grouping.available_grace_credits).to eq(0)

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
            expect(student_membership.user.remaining_grace_credits).to eq(members[student_membership.user.id])
          end

          # We should have all files except NotIncluded.java in the repository.
          expect(submission.submission_files.find_by_filename('TestFile.java')).not_to be_nil
          expect(submission.submission_files.find_by_filename('Test.java')).not_to be_nil
          expect(submission.submission_files.find_by_filename('Driver.java')).not_to be_nil
          expect(submission.submission_files.find_by_filename('OvertimeFile2.java')).not_to be_nil
          expect(submission.submission_files.find_by_filename('NotIncluded.java')).to be_nil
          expect(submission.get_latest_result).not_to be_nil
        end
      end
    end

    context 'submit assignment 1 on time and submit assignment 2 before assignment 1 collection time' do
      before :each do
        @grouping2 = create(:grouping, group: @group)
        @membership2 = create(:student_membership, grouping: @grouping2, membership_status: StudentMembership::STATUSES[:inviter])
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

      # Regression test for issue 656.  The issue is when submitting files for an assignment before the grace period
      # of the previous assignment is over.  When calculating grace days for the previous assignment, it
      # takes the newer assignment submission as the submission time.  Therefore, grace days are being
      # taken off when it shouldn't have.
      it 'deducts 0 grace credits' do

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
            expect(student_membership.user.remaining_grace_credits).to eq(members[student_membership.user.id])
          end

          # We should have all files except OvertimeFile1.java and NotIncluded.java in the repository.
          expect(submission.submission_files.find_by_filename('TestFile.java')).not_to be_nil
          expect(submission.submission_files.find_by_filename('Test.java')).not_to be_nil
          expect(submission.submission_files.find_by_filename('Driver.java')).not_to be_nil
          expect(submission.submission_files.find_by_filename('OvertimeFile1.java')).to be_nil
          expect(submission.submission_files.find_by_filename('NotIncluded.java')).to be_nil
          expect(submission.get_latest_result).not_to be_nil
        end
      end

      # Regression test for issue 656.  The issue is when submitting files for an assignment before the grace period
      # of the previous assignment is over.  When calculating grace days for the previous assignment, it
      # takes the newer assignment submission as the submission time.  Therefore, grace days are being
      # taken off when it shouldn't have.
      it 'deducts 1 grace credits' do

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
            expect(student_membership.user.remaining_grace_credits).to eq(members[student_membership.user.id]-1)
          end

          # We should have all files except NotIncluded.java in the repository.
          expect(submission.submission_files.find_by_filename('TestFile.java')).not_to be_nil
          expect(submission.submission_files.find_by_filename('Test.java')).not_to be_nil
          expect(submission.submission_files.find_by_filename('Driver.java')).not_to be_nil
          expect(submission.submission_files.find_by_filename('OvertimeFile1.java')).not_to be_nil
          expect(submission.submission_files.find_by_filename('NotIncluded.java')).to be_nil
          expect(submission.get_latest_result).not_to be_nil
        end
      end
    end
  end

  private

  def submit_files_before_due_date
    pretend_now_is(Time.parse('July 20 2009 5:00PM')) do
      expect(Time.now).to be < @assignment.due_date
      expect(Time.now).to be < @assignment.submission_rule.calculate_collection_time
      expect(Time.now).to be < @assignment.submission_rule.calculate_grouping_collection_time(@membership.grouping)

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
      expect(Time.now).to be > @assignment.due_date
      expect(Time.now).to be < @assignment.submission_rule.calculate_collection_time

      @group.access_repo do |repo|
        txn = repo.get_transaction('test')
        txn = add_file_helper(@assignment, txn, filename, text)
        repo.commit(txn)
      end
    end
  end

  def submit_files_after_due_date_after_collection_time(time, filename, text)
    pretend_now_is(Time.parse(time)) do
      expect(Time.now).to be > @assignment.due_date
      expect(Time.now).to be > @assignment.submission_rule.calculate_collection_time

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
      expect(Time.now).to be > @assignment.due_date
      expect(Time.now).to be < @assignment.submission_rule.calculate_collection_time

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
