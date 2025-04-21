describe SubmissionsJob do
  let(:assignment) { create(:assignment) }
  let(:groupings) { create_list(:grouping_with_inviter, 3, assignment: assignment) }

  context 'when running as a background job' do
    let(:job_args) { [groupings] }

    it_behaves_like 'background job'
  end

  context 'when creating a submission by timestamp' do
    let(:job_kwargs) { {} }

    before do
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
    before do
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
        revision_id = revision_ids[groupings.first.id] + 'aaaaa'
        expect { SubmissionsJob.perform_now(groupings[0...1], revision_identifier: revision_id) }
          .to raise_error(Repository::RevisionDoesNotExist)

        g = groupings.first.reload
        expect(g.current_submission_used).to be_nil
      end
    end
  end

  context 'when creating a submission for a scanned exam' do
    let(:assignment) { create(:assignment_for_scanned_exam) }

    before do
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
          expect(g.reload.current_submission_used.reload.revision_identifier).to be_nil
        end
      end
    end
  end

  context 'when collecting submissions with collect_current set to true' do
    let(:assignment) { create(:assignment) }

    before do
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
      let(:assignment) { create(:assignment, due_date: 1.week.ago) }
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
      let(:assignment) { create(:assignment, due_date: 1.hour.from_now) }
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

  context 'when collecting submissions with retain_existing_grading set to true' do
    let(:submission_date) { Time.current.to_s }
    let(:groupings) { create_list(:grouping_with_inviter_and_submission, 3, assignment: assignment) }

    it 'calls the Submission#copy_grading_data method' do
      receive_count = 0
      allow_any_instance_of(Submission).to receive(:copy_grading_data) { receive_count += 1 }

      SubmissionsJob.perform_now(groupings, retain_existing_grading: true)

      expect(receive_count).to eq(groupings.size)
    end

    it 'does not make a new submission on any grouping when there is an error' do
      allow_any_instance_of(Submission).to receive(:copy_grading_data).and_raise(ActiveRecord::RecordInvalid)
      old_submissions = groupings.map { |g| g.current_submission_used.id }.sort

      SubmissionsJob.perform_now(groupings, retain_existing_grading: true)

      # no groupings should have new submissions
      expect(groupings.map { |g| g.reload.current_submission_used.id }.sort).to eq(old_submissions)
    end
  end

  context 'when notify_socket flag is set to true and enqueuing_user contains a valid user' do
    let(:instructor) { create(:instructor) }
    let(:instructor2) { create(:instructor) }

    context 'without errors when collecting submissions' do
      it 'broadcasts status updates for each collected submission, once upon completion, and once to update the ' \
         'table' do
        (1..3).each do |i|
          expect(CollectSubmissionsChannel).to receive(:broadcast_to) do |_, options|
            expect(options[:status]).to be(:working)
            expect(options[:progress]).to eq(i)
            expect(options[:total]).to eq(3)
            expect(options.count).to eq(3)
          end
        end
        expect(CollectSubmissionsChannel).to receive(:broadcast_to) do |_, options|
          expect(options[:status]).to be(:completed)
          expect(options[:update_table]).not_to be_nil
          expect(options.count).to eq(2)
        end
        SubmissionsJob.perform_now(groupings, enqueuing_user: instructor.user, notify_socket: true)
      end

      it 'broadcasts a warning message if it is present' do
        # making it so that error messages are set
        2.times do |i|
          allow(groupings[i]).to receive(:save) do
            groupings[i].errors.add(:is_collected)
          end
        end
        expect(CollectSubmissionsChannel).to receive(:broadcast_to) do |_, options|
          expect(options[:warning_message]).to eq('Is collected is invalid')
        end
        3.times do |_|
          expect(CollectSubmissionsChannel).to receive(:broadcast_to) do |_, options|
            expect(options[:warning_message]).to eq("Is collected is invalid\nIs collected is invalid")
          end
        end
        SubmissionsJob.perform_now(groupings, enqueuing_user: instructor.user, notify_socket: true)
      end

      it 'broadcasts exactly four messages (three status updates and one joint status and table update)' do
        expect { SubmissionsJob.perform_now(groupings, enqueuing_user: instructor.user, notify_socket: true) }
          .to have_broadcasted_to(instructor.user).from_channel(CollectSubmissionsChannel).exactly 4
      end
    end

    context 'with errors when collecting submissions' do
      before do
        allow(groupings[1]).to receive(:save).and_raise(StandardError)
      end

      it 'sends all status updates prior to the error, the error itself, and one to update the submissions table' do
        expect(CollectSubmissionsChannel).to receive(:broadcast_to) do |_, options|
          expect(options[:status]).to be(:working)
          expect(options[:progress]).to eq(1)
          expect(options[:total]).to eq(3)
          expect(options.count).to eq(3)
        end
        expect(CollectSubmissionsChannel).to receive(:broadcast_to) do |_, options|
          expect(options[:status]).to be(:failed)
          expect(options[:update_table]).not_to be_nil
        end
        expect do
          SubmissionsJob.perform_now(groupings, enqueuing_user: instructor.user, notify_socket: true)
        end.to raise_error(StandardError)
      end

      it 'sends exactly two status updates (one when the first submission is collected and a joint one for the error' \
         'and table update)' do
        expect(CollectSubmissionsChannel).to receive(:broadcast_to).twice
        expect do
          SubmissionsJob.perform_now(groupings, enqueuing_user: instructor.user, notify_socket: true)
        end.to raise_error(StandardError)
      end

      it 'broadcasts a warning message if present' do
        allow(groupings[0]).to receive(:save) do
          groupings[0].errors.add(:is_collected)
        end
        2.times do |_|
          expect(CollectSubmissionsChannel).to receive(:broadcast_to) do |_, options|
            expect(options[:warning_message]).to eq('Is collected is invalid')
          end
        end
        expect do
          SubmissionsJob.perform_now(groupings, enqueuing_user: instructor.user, notify_socket: true)
        end.to raise_error(StandardError)
      end
    end

    it "doesn't broadcast the message to other users" do
      expect { SubmissionsJob.perform_now(groupings, enqueuing_user: instructor.user, notify_socket: true) }
        .to have_broadcasted_to(instructor2.user).from_channel(CollectSubmissionsChannel).exactly 0
    end
  end

  context 'when notify_socket flag is not set' do
    let(:instructor) { create(:instructor) }

    it "doesn't broadcast a message" do
      expect { SubmissionsJob.perform_now(groupings, enqueuing_user: instructor.user) }
        .to have_broadcasted_to(instructor.user).from_channel(CollectSubmissionsChannel).exactly 0
    end
  end

  context 'when enqueuing user is not set' do
    let(:instructor) { create(:instructor) }

    it "doesn't broadcast a message" do
      expect { SubmissionsJob.perform_now(groupings, notify_socket: true) }
        .to have_broadcasted_to(instructor.user).from_channel(CollectSubmissionsChannel).exactly 0
    end
  end

  xcontext 'when applying a late penalty' do
    # TODO: the following tests are failing on travis occasionally. Figure out why and re-enable them.
    before do
      create(:period, submission_rule: submission_rule, hours: 2)
      groupings.each do |g|
        submit_file_at_time(g.assignment, g.group, 'test', (g.due_date + 1.hour).to_s, 'test.txt', 'aaa')
        g.reload
      end
    end

    context 'for a grace period deduction' do
      let(:submission_rule) { create(:grace_period_submission_rule, assignment: assignment) }

      before do
        groupings.each do |g|
          g.inviter_membership.user.update(grace_credits: 5)
          create(:grace_period_deduction, membership: g.inviter_membership)
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
      let(:submission_rule) { create(:penalty_decay_period_submission_rule, assignment: assignment) }

      it 'should add a deduction' do
        SubmissionsJob.perform_now(groupings, apply_late_penalty: true)
        groupings.each do |g|
          expect(g.current_result.extra_marks.length).to eq 1
        end
      end
    end

    context 'for a penalty period deduction' do
      let(:submission_rule) { create(:penalty_period_submission_rule, assignment: assignment) }

      it 'should add a deduction' do
        SubmissionsJob.perform_now(groupings, apply_late_penalty: true)
        groupings.each do |g|
          expect(g.current_result.extra_marks.length).to eq 1
        end
      end
    end
  end
end
