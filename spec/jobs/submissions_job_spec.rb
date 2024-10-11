describe SubmissionsJob do
  let(:assignment) { create(:assignment) }
  let(:groupings) { create_list(:grouping_with_inviter, 3, assignment: assignment) }

  context 'when running as a background job' do
    let(:job_args) { [groupings] }

    include_examples 'background job'
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
    let(:assignment) { create(:assignment_with_criteria_and_results) }

    before do
      # explicit storing and freezing here or it may implicitly reload this and
      # we can't compare to the old one
      @original_submissions = assignment.reload.current_submissions_used.to_a
      @original_results = assignment.current_results.to_a

      SubmissionsJob.perform_now(assignment.groupings, retain_existing_grading: true)

      @new_submissions = assignment.reload.current_submissions_used
      @new_results = assignment.reload.current_results
    end

    it 'creates the correct number of new submissions' do
      # still the same number of groupings => the same number of submissions
      expect(@new_submissions.size).to eq(@original_submissions.size)
      expect(@new_submissions.ids).not_to eq(@original_submissions.map(&:id))
    end

    it 'creates the correct number of new results' do
      # still the same number of submissions => the same number of results
      expect(@new_results.size).to eq(@original_results.size)
      expect(@new_results.ids).not_to eq(@original_results.map(&:id))
    end

    context 'for feedback files on each new submission' do
      let(:assignment) { create(:assignment_with_criteria_and_results_and_feedback_files) }

      it 'creates the correct number of new feedback files on each submission' do
        @new_submissions.zip(@original_submissions).each do |new_submission, old_submission|
          expect(new_submission.feedback_files.size).to eq(old_submission.feedback_files.size)
          expect(new_submission.feedback_files.ids).not_to eq(old_submission.feedback_files.ids)
        end
      end

      it 'retains the file name on each new feedback file' do
        @new_submissions.zip(@original_submissions).each do |new_submission, old_submission|
          expect(new_submission.feedback_files.map(&:filename)).to eq(old_submission.feedback_files.map(&:filename))
        end
      end
    end

    context 'for automated tests on each new submission' do
      let(:assignment) { create(:assignment_with_criteria_and_test_results_and_feedback_files) }

      it 'creates the correct number of new test runs' do
        @new_submissions.zip(@original_submissions).each do |new_submission, old_submission|
          expect(new_submission.test_runs.size).to eq(old_submission.test_runs.size)
          expect(new_submission.test_runs.ids).not_to eq(old_submission.test_runs.ids)
        end
      end

      context 'for each new test run' do
        it 'creates the correct number of new test group results' do
          @new_submissions.zip(@original_submissions).each do |new_submission, old_submission|
            new_submission.test_runs.zip(old_submission.test_runs).each do |old_test_run, new_test_run|
              expect(new_test_run.test_group_results.size).to eq(old_test_run.test_group_results.size)
              expect(new_test_run.test_group_results.ids).not_to eq(old_test_run.test_group_results.ids)
            end
          end
        end

        context 'for each new test group results' do
          it 'creates the correct number of new test results' do
            @new_submissions.zip(@original_submissions).each do |new_submission, old_submission|
              new_submission.test_runs.zip(old_submission.test_runs).each do |old_test_run, new_test_run|
                new_test_run.test_group_results.zip(old_test_run.test_group_results).each do |old_tgr, new_tgr|
                  expect(new_tgr.test_results.size).to eq(old_tgr.test_results.size)
                  expect(new_tgr.test_results.ids).not_to eq(old_tgr.test_results.ids)
                end
              end
            end
          end

          it 'creates the correct number of new feedback files' do
            @new_submissions.zip(@original_submissions).each do |new_submission, old_submission|
              new_submission.test_runs.zip(old_submission.test_runs).each do |old_test_run, new_test_run|
                new_test_run.test_group_results.zip(old_test_run.test_group_results).each do |old_tgr, new_tgr|
                  expect(new_tgr.feedback_files.size).to eq(old_tgr.feedback_files.size)
                  expect(new_tgr.feedback_files.ids).not_to eq(old_tgr.feedback_files.ids)
                end
              end
            end
          end
        end
      end
    end

    context 'for each new result that is created' do
      context 'for remark data' do
        let(:assignment) { create(:assignment_with_criteria_and_results_with_remark) }

        it 'does not copy over remark information' do
          expect(@new_results.all? { |result| result.remark_request_submitted_at.nil? }).to be(true)
        end

        it 'retains the marks from each original submission\'s original result' do
          @new_submissions.zip(@original_submissions).each do |new_submission, old_submission|
            # the last result in each submission is the original one in the old submission
            expect(new_submission.current_result.marks.map(&:mark)).to eq(old_submission
              .get_original_result.marks.map(&:mark))
          end
        end
      end

      context 'for marks' do
        it 'creates the correct number of new marks for each result' do
          @new_results.zip(@original_results).each do |new_result, old_result|
            expect(new_result.marks.size).to eq(old_result.marks.size)
            expect(new_result.marks.ids).not_to eq(old_result.marks.ids)
          end
        end

        it 'retains the correct mark values for each result' do
          @new_results.zip(@original_results).each do |new_result, old_result|
            expect(new_result.marks.map(&:mark)).to eq(old_result.marks.map(&:mark))
          end
        end
      end

      context 'for annotations' do
        let(:assignment) { create(:assignment_with_deductive_annotations_and_submission_files) }

        it 'creates the correct number of new annotations for each result' do
          @new_results.reload.zip(@original_results).each do |new_result, old_result|
            expect(new_result.annotations.size).to eq(old_result.annotations.size)
            expect(new_result.annotations.ids).not_to eq(old_result.annotations.ids)
          end
        end

        it 'retains the mark deductions from deductive annotations' do
          @new_results.zip(@original_results).each do |new_result, old_result|
            expect(new_result.marks.map(&:calculate_deduction)).to eq(old_result.marks.map(&:calculate_deduction))
          end
        end

        it 'retains the text from each annotation' do
          @new_results.zip(@original_results).each do |new_result, old_result|
            expect(new_result.annotations.map { |a| a.annotation_text.content }).to eq(old_result.annotations.map do |a|
              a.annotation_text.content
            end)
          end
        end
      end

      context 'for extra marks' do
        let(:assignment) { create(:assignment_with_criteria_and_results_and_extra_marks) }

        it 'creates the correct number of new extra marks for each result' do
          @new_results.zip(@original_results).each do |new_result, old_result|
            expect(new_result.extra_marks.size).to eq(old_result.extra_marks.size)
            expect(new_result.extra_marks.ids).not_to eq(old_result.extra_marks.ids)
          end
        end

        it 'retains the correct mark values for each result' do
          @new_results.zip(@original_results).each do |new_result, old_result|
            expect(new_result.extra_marks.map(&:extra_mark)).to eq(old_result.extra_marks.map(&:extra_mark))
          end
        end
      end
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
