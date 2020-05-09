shared_examples '#apply_submission_rule' do
  context 'When an assignment has two periods of 24 hours each after due date' do
    let(:due_date) { Time.parse('July 23 2009 5:00PM') }
    let(:assignment) { create :assignment, due_date: due_date }
    let(:grouping) { create :grouping_with_inviter, assignment: assignment }
    let(:rule) { create rule_type, assignment: assignment }
    let!(:periods) { create_list :period, 2, submission_rule: rule, hours: 24, interval: 24 }

    after :each do
      destroy_repos
    end

    let(:submission) { Submission.create_by_timestamp(grouping, rule.calculate_collection_time) }
    let(:apply_rule) do
      rule.reload.apply_submission_rule(submission)
      grouping.reload
    end
    describe 'when the submission is on time' do
      before :each do
        # The Student submits their files before the due date
        pretend_now_is(due_date - 3.days) { grouping.create_grouping_repository_folder }
        submit_file_at_time(assignment, grouping.group, 'test', (due_date - 2.days).to_s, 'TestFile.java',
                            'Some contents for TestFile.java')
      end
      it_behaves_like 'on_time'
    end
    describe 'when the submission falls in the first grace period' do
      before :each do
        pretend_now_is(due_date - 3.days) { grouping.create_grouping_repository_folder }

        # Now we're past the due date, but before the collection date.
        submit_file_at_time(assignment, grouping.group, 'test', (due_date + 10.hours).to_s, 'OvertimeFile.java',
                            'Some overtime contents')

        # Now we're past the collection date.
        submit_file_at_time(assignment, grouping.group, 'test', (due_date + 5.days).to_s, 'NotIncluded.java',
                            'Should not be included in grading')
      end
      it_behaves_like 'during_first'
    end
    describe 'when the submission falls in the second period' do
      before :each do
        pretend_now_is(due_date - 3.days) { grouping.create_grouping_repository_folder }

        # Now we're past the due date, but before the collection date, within the first grace period
        submit_file_at_time(assignment, grouping.group, 'test', (due_date + 10.hours).to_s, 'OvertimeFile1.java',
                            'Some overtime contents')

        # Now we're past the due date, but before the collection date.
        submit_file_at_time(assignment, grouping.group, 'test', (due_date + 34.hours).to_s, 'OvertimeFile2.java',
                            'Some overtime contents')

        # Now we're past the collection date.
        submit_file_at_time(assignment, grouping.group, 'test', (due_date + 5.days).to_s, 'NotIncluded.java',
                            'Should not be included in grading')
      end
      it_behaves_like 'during_second'
    end
  end
end
