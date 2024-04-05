shared_context 'submission_rule' do
  let(:due_date) { Time.zone.parse('July 23 2009 5:00PM') }
  let(:assignment) { create(:assignment, due_date: due_date) }
  let(:grouping) { create(:grouping_with_inviter, assignment: assignment) }
  let(:rule) { create(rule_type, assignment: assignment) }
  let(:submission) { Submission.create_by_timestamp(grouping, rule.calculate_collection_time) }
  let(:apply_rule) do
    rule.reload.apply_submission_rule(submission)
    grouping.reload
  end

  before { create_list(:period, 2, submission_rule: rule, hours: 24, interval: 24) }

  after do
    destroy_repos
  end
end

shared_context 'submission_rule_on_time' do
  # the submission is on time
  include_context 'submission_rule'
  before do
    # The Student submits their files before the due date
    pretend_now_is(due_date - 3.days) { grouping }
    submit_file_at_time(assignment, grouping.group, 'test', (due_date - 2.days).to_s, 'TestFile.java',
                        'Some contents for TestFile.java')
  end
end

shared_context 'submission_rule_during_first' do
  # the submission was submitted during the first penalty period
  include_context 'submission_rule'
  before do
    pretend_now_is(due_date - 3.days) { grouping }

    # Now we're past the due date, but before the collection date.
    submit_file_at_time(assignment, grouping.group, 'test', (due_date + 10.hours).to_s, 'OvertimeFile.java',
                        'Some overtime contents')

    # Now we're past the collection date.
    submit_file_at_time(assignment, grouping.group, 'test', (due_date + 5.days).to_s, 'NotIncluded.java',
                        'Should not be included in grading')
  end
end

shared_context 'submission_rule_during_second' do
  # the submission was submitted during the second penalty period
  include_context 'submission_rule'
  before do
    pretend_now_is(due_date - 3.days) { grouping }

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
end
