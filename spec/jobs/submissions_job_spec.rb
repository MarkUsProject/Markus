describe SubmissionsJob do
  let(:assignment) { create :assignment }
  let(:groupings) { create_list(:grouping_with_inviter, 3, assignment: assignment) }

  context 'when running as a background job' do
    let(:job_args) { [groupings] }
    include_examples 'background job'
  end

  context 'when creating a submission by timestamp' do
    let(:job_kwargs) { {} }
    before :each do
      groupings.each do |g|
        date = collection_dates[g.id]
        submit_file_at_time(g.assignment, g.group, 'test', date.to_s, 'test.txt', 'aaa') unless date.nil?
      end
      SubmissionsJob.perform_now(groupings, **job_kwargs)
    end

    context 'when a submission exists before the grouping\'s collection date' do
      let(:collection_dates) { groupings.map { |g| [g.id, g.collection_date - 1.hour] }.to_h }
      it 'collects the latest revision' do
        groupings.each do |g|
          g.reload
          latest_revision = g.group.access_repo { |repo| repo.get_latest_revision.revision_identifier }
          expect(g.current_submission_used.revision_identifier).to eq latest_revision.to_s
        end
      end
    end
    context 'when a submission does not exist before a grouping\'s collection date' do
      let(:collection_dates) { groupings.map { |g| [g.id, g.collection_date + 1.hour] }.to_h }
      it 'collects a nil revision' do
        groupings.each do |g|
          expect(g.reload.current_submission_used.revision_identifier).to be_nil
        end
      end
    end
    context 'when a submission exists before the given collection date' do
      let(:collection_dates) { groupings.map { |g| [g.id, 1.hour.ago] }.to_h }
      let(:job_kwargs) { { collection_dates: groupings.map { |g| [g.id, Time.current] }.to_h } }
      it 'collects the latest revision' do
        groupings.each do |g|
          g.reload
          latest_revision = g.group.access_repo { |repo| repo.get_latest_revision.revision_identifier }
          expect(g.current_submission_used.revision_identifier).to eq latest_revision.to_s
        end
      end
    end
    context 'when a submission does not exist before the given collection date' do
      let(:collection_dates) { groupings.map { |g| [g.id, 1.hour.from_now] }.to_h }
      let(:job_kwargs) { { collection_dates: groupings.map { |g| [g.id, Time.current] }.to_h } }
      it 'collects a nil revision' do
        groupings.each do |g|
          expect(g.reload.current_submission_used.revision_identifier).to be_nil
        end
      end
    end
    context 'when a submission does not exist' do
      let(:collection_dates) { groupings.map { |g| [g.id, nil] }.to_h }
      it 'collects a nil revision' do
        groupings.each do |g|
          expect(g.reload.current_submission_used.revision_identifier).to be_nil
        end
      end
    end
  end
  context 'when creating a submission by revision id' do
    before :each do
      groupings.each { |g| submit_file_at_time(g.assignment, g.group, 'test', Time.current.to_s, 'test.txt', 'aaa') }
    end
    let(:revision_ids) do
      groupings.map do |g|
        [g.id, g.group.access_repo { |repo| repo.get_latest_revision.revision_identifier.to_s }]
      end.to_h
    end
    context 'when a revision id exists in the repo for the group' do
      it 'should collect the specified revision' do
        SubmissionsJob.perform_now(groupings[0...1], revision_identifier: revision_ids[groupings.first.id])
        g = groupings.first.reload
        expect(g.current_submission_used.revision_identifier).to eq revision_ids[g.id]
      end
    end
    context 'when a revision id does not exist in the repo for the group' do
      it 'should not create a submission' do
        SubmissionsJob.perform_now(groupings[0...1], revision_identifier: revision_ids[groupings.first.id] + 'aaaaa')
        g = groupings.first.reload
        expect(g.current_submission_used).to be_nil
      end
    end
  end

  context 'when creating a submission for a scanned exam' do
    let(:assignment) { create :assignment_for_scanned_exam }
    before :each do
      groupings.each { |g| submit_file_at_time(g.assignment, g.group, 'test', submission_date, 'test.txt', 'aaa') }
      SubmissionsJob.perform_now(groupings)
    end
    context 'when submitted before collecting' do
      let(:submission_date) { Time.current.to_s }
      it 'collects the latest revision' do
        groupings.each do |g|
          g.reload
          latest_revision = g.group.access_repo { |repo| repo.get_latest_revision.revision_identifier }
          expect(g.current_submission_used.revision_identifier).to eq latest_revision.to_s
        end
      end
    end

    context 'when submitted after collecting' do
      let(:submission_date) { 1.hour.from_now.to_s }
      it 'collects a nil revision' do
        groupings.each do |g|
          expect(g.reload.current_submission_used.revision_identifier).to be_nil
        end
      end
    end
  end

  context 'when collecting submissions with collect_current set to true' do
    let(:assignment) { create :assignment }
    before :each do
      groupings.each { |g| submit_file_at_time(g.assignment, g.group, 'test', submission_date, 'test.txt', 'aaa') }
      SubmissionsJob.perform_now(groupings, collect_current: true)
    end
    context 'when submitted before collecting' do
      let(:submission_date) { Time.current.to_s }
      it 'collects the latest revision' do
        groupings.each do |g|
          g.reload
          latest_revision = g.group.access_repo { |repo| repo.get_latest_revision.revision_identifier }
          expect(g.current_submission_used.revision_identifier).to eq latest_revision.to_s
        end
      end
    end

    context 'when collected after due date' do
      let(:assignment) { create :assignment, due_date: 1.week.ago }
      let(:submission_date) { Time.current.to_s }
      it 'collects the most recent revision' do
        groupings.each do |g|
          g.reload
          latest_revision = g.group.access_repo { |repo| repo.get_latest_revision.revision_identifier }
          expect(g.current_submission_used.revision_identifier).to eq latest_revision.to_s
        end
      end
    end
    context 'when collected before due date' do
      let(:assignment) { create :assignment, due_date: 1.hour.from_now }
      let(:submission_date) { Time.current.to_s }
      it 'collects the latest revision' do
        groupings.each do |g|
          g.reload
          latest_revision = g.group.access_repo { |repo| repo.get_latest_revision.revision_identifier }
          expect(g.current_submission_used.revision_identifier).to eq latest_revision.to_s
        end
      end
    end
  end

  xcontext 'when applying a late penalty' do
    # TODO: the following tests are failing on travis occasionally. Figure out why and re-enable them.
    let!(:period) { create :period, submission_rule: submission_rule, hours: 2 }
    before :each do
      groupings.each do |g|
        submit_file_at_time(g.assignment, g.group, 'test', (g.due_date + 1.hour).to_s, 'test.txt', 'aaa')
        g.reload
      end
    end
    context 'for a grace period deduction' do
      let(:submission_rule) { create :grace_period_submission_rule, assignment: assignment }
      before :each do
        groupings.each do |g|
          g.inviter_membership.user.update(grace_credits: 5)
          create :grace_period_deduction, membership: g.inviter_membership
        end
      end
      it 'should remove any previous deductions' do
        SubmissionsJob.perform_now(groupings, apply_late_penalty: false)
        groupings.each do |g|
          expect(g.reload.grace_period_deductions).to be_empty
        end
      end
      it 'should add a deduction' do
        SubmissionsJob.perform_now(groupings, apply_late_penalty: true)
        groupings.each do |g|
          expect(g.inviter_membership.user.reload.remaining_grace_credits).to eq 4
        end
      end
    end
    context 'for a penalty decay deduction' do
      let(:submission_rule) { create :penalty_decay_period_submission_rule, assignment: assignment }
      it 'should add a deduction' do
        SubmissionsJob.perform_now(groupings, apply_late_penalty: true)
        groupings.each do |g|
          expect(g.current_result.extra_marks.length).to eq 1
        end
      end
    end
    context 'for a penalty period deduction' do
      let(:submission_rule) { create :penalty_period_submission_rule, assignment: assignment }
      it 'should add a deduction' do
        SubmissionsJob.perform_now(groupings, apply_late_penalty: true)
        groupings.each do |g|
          expect(g.current_result.extra_marks.length).to eq 1
        end
      end
    end
  end
end
