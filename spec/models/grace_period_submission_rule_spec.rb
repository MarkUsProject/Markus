describe GracePeriodSubmissionRule do
  let(:rule_type) { :grace_period_submission_rule }

  it { is_expected.to have_one(:course) }

  context 'when the group submitted on time' do
    include_context 'submission_rule_on_time'
    context 'when the student submitted some files' do
      it 'does not deduct credits' do
        expect { apply_rule }.not_to(change { grouping.inviter.grace_period_deductions.count })
      end
    end

    context 'when the student did not submit any files' do
      before do
        pretend_now_is(collection_time) { grouping }
      end

      let(:submission) { create(:version_used_submission, grouping: grouping, is_empty: true) }
      let(:collection_time) { due_date - 5.days }

      it 'does not deduct credits' do
        expect { apply_rule }.not_to(change { grouping.inviter.grace_period_deductions.count })
      end
    end
  end

  context 'when the group submitted during the first penalty period' do
    include_context 'submission_rule_during_first'
    context 'when the student did not submit any files' do
      before do
        pretend_now_is(collection_time) { grouping }
      end

      let(:submission) { create(:version_used_submission, grouping: grouping, is_empty: true) }
      let(:collection_time) { due_date + 12.hours }

      it 'does not deduct credits' do
        expect { apply_rule }.not_to(change { grouping.inviter.grace_period_deductions.count })
      end
    end

    context 'when the student submitted some files' do
      it 'should create a new deduction' do
        expect { apply_rule }.to(change { grouping.inviter.grace_period_deductions.count }.by(1))
      end

      it 'should deduct one grace credit' do
        apply_rule
        expect(grouping.inviter.grace_period_deductions.sum(&:deduction)).to eq 1
      end

      describe 'when the student has no grace credits' do
        before do
          grouping.inviter.update!(grace_credits: 0)
        end

        it 'does not deduct credits' do
          expect { apply_rule }.not_to(change { grouping.reload.grace_period_deductions.count })
        end

        it 'should collect an empty submission' do
          apply_rule
          expect(grouping.current_submission_used.is_empty).to be true
        end
      end
    end

    context 'submit assignment 1 on time and submit assignment 2 before assignment 1 collection time' do
      # Regression test for issue 656.  The issue is when submitting files for an assignment before the grace period
      # of the previous assignment is over.  When calculating grace days for the previous assignment, it
      # takes the newer assignment submission as the submission time.  Therefore, grace days are being
      # taken off when it shouldn't have.
      let(:due_date2) { due_date + 5.days }
      let(:assignment2) { create(:assignment, due_date: due_date2) }
      let(:grouping2) { create(:grouping_with_inviter, assignment: assignment2) }
      let(:rule2) { create(:grace_period_submission_rule, assignment: assignment2) }

      before do
        create_list(:period, 2, submission_rule: rule2, hours: 24)
      end

      context 'when submitting on time before grace period of previous assignment is over' do
        before do
          # The Student submits their files before the due date
          pretend_now_is(due_date - 3.days) { grouping }
          submit_file_at_time(assignment, grouping.group, 'test', (due_date - 2.days).to_s, 'TestFile.java',
                              'Some contents for TestFile.java')

          # Now we're past the due date, but before the collection date, within the first
          # grace period.  Submit files for Assignment 2
          submit_file_at_time(assignment2, grouping2.group, 'test1', (due_date + 10.hours).to_s, 'NotIncluded.java',
                              'Not Included in Assignment 1')
        end

        it 'does not deduct credits' do
          expect { apply_rule }.not_to(change { grouping.inviter.grace_period_deductions.count })
        end
      end

      context 'when submitting overtime before the grace period of previous assignment is over' do
        before do
          # The Student submits their files before the due date
          pretend_now_is(due_date - 3.days) { grouping }

          submit_file_at_time(assignment, grouping.group, 'test', (due_date + 10.hours).to_s, 'OvertimeFile1.java',
                              'Some overtime contents')

          # Now we're past the due date, but before the collection date, within the first
          # grace period.  Submit files for Assignment 2
          submit_file_at_time(assignment2, grouping2.group, 'test1', (due_date + 10.hours).to_s, 'NotIncluded.java',
                              'Not Included in Assignment 1')
        end

        it 'should create a new deduction' do
          expect { apply_rule }.to(change { grouping.inviter.grace_period_deductions.count }.by(1))
        end

        it 'should deduct one grace credit' do
          apply_rule
          expect(grouping.inviter.grace_period_deductions.sum(&:deduction)).to eq 1
        end
      end
    end
  end

  context 'when the group submitted during the second penalty period' do
    include_context 'submission_rule_during_second'
    it 'should create a new deduction' do
      expect { apply_rule }.to(change { grouping.inviter.grace_period_deductions.count }.by(1))
    end

    it 'should deduct two grace credits' do
      apply_rule
      expect(grouping.inviter.grace_period_deductions.sum(&:deduction)).to eq 2
    end

    describe 'when the student has no grace credits' do
      before do
        grouping.inviter.update!(grace_credits: 0)
      end

      it 'does not deduct credits' do
        expect { apply_rule }.not_to(change { grouping.reload.grace_period_deductions.count })
      end
    end

    describe 'when the student has one grace credits' do
      before do
        grouping.inviter.update!(grace_credits: 1)
      end

      it 'should create a new deduction' do
        expect { apply_rule }.to(change { grouping.inviter.grace_period_deductions.count }.by(1))
      end

      it 'should deduct one grace credit' do
        apply_rule
        expect(grouping.inviter.grace_period_deductions.sum(&:deduction)).to eq 1
      end

      it 'should collect a submission from the first penalty period' do
        apply_rule
        timestamp = grouping.current_submission_used.revision_timestamp.utc
        expect(timestamp).to be_within(1.second).of(due_date + 10.hours)
      end
    end
  end
end
