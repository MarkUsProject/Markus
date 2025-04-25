describe AutotestRunJob do
  let(:host_with_port) { 'http://localhost:3000' }
  let(:assignment) { create(:assignment) }
  let(:n_groups) { 3 }
  let(:groupings) { create_list(:grouping_with_inviter_and_submission, n_groups, assignment: assignment) }
  let(:groups) { groupings.map(&:group) }
  let(:role) { create(:instructor) }

  before do
    allow_any_instance_of(AutotestSetting).to(
      receive(:send_request!).and_return(OpenStruct.new(body: { api_key: 'someapikey' }.to_json))
    )
    course = create(:course)
    course.autotest_setting = create(:autotest_setting)
    course.save
  end

  context 'when running as a background job' do
    let(:job_args) { [host_with_port, role.id, assignment.id, groups.map(&:id)] }

    before { allow(AutotestResultsJob).to receive(:set) }

    it_behaves_like 'background job'
  end

  describe '#perform' do
    subject do
      AutotestRunJob.perform_now(host_with_port, role.id, assignment.id, groups.map(&:id),
                                 user: role.user,
                                 collected: collected)
    end

    after do
      clear_enqueued_jobs
      clear_performed_jobs
    end

    let(:collected) { true }

    context 'when tests are set up for an assignment' do
      let(:assignment) { create(:assignment, assignment_properties_attributes: { remote_autotest_settings_id: 10 }) }
      let(:dummy_return) { OpenStruct.new(body: { 'test_ids' => (1..n_groups).to_a }.to_json) }
      let(:test_data) do
        url_root = Rails.configuration.relative_url_root
        groups.map do |group|
          file_url = "http://localhost:3000#{url_root}/api/courses/#{assignment.course.id}/assignments/" \
                     "#{assignment.id}/groups/#{group.id}/submission_files?#{collected ? 'collected=true' : ''}"
          starter_files = assignment.groupings
                                    .joins(starter_file_entries: :starter_file_group)
                                    .where(group_id: group.id)
                                    .pluck('starter_file_entries.path', 'starter_file_groups.name')
                                    .filter_map do |v|
            { starter_file_group: v.second, starter_file_path: v.first } if v.first
          end
          starter_files.sort_by! { |x| [x[:starter_file_group], x[:starter_file_path]] }

          {
            file_url: file_url,
            env_vars: { MARKUS_GROUP: group.group_name, MARKUS_STARTER_FILES: starter_files.to_json }
          }.deep_stringify_keys
        end
      end

      before do
        allow_any_instance_of(AutotestRunJob).to receive(:send_request!).and_return(dummy_return)
      end

      context 'when there is only one group' do
        let(:user2) { create(:instructor) }
        let(:n_groups) { 1 }

        it 'should not create a batch' do
          expect { subject }.not_to(change { TestBatch.count })
        end

        it 'should create a test run without an associated batch' do
          subject
          expect(TestRun.where(batch_id: nil)).not_to be_nil
        end

        it 'should broadcast a message to the user' do
          expect { subject }
            .to have_broadcasted_to(role.user).from_channel(TestRunsChannel)
                                              .with(status: 'completed', job_class: 'AutotestRunJob')
        end

        it 'should broadcast exactly one message' do
          expect { subject }
            .to have_broadcasted_to(role.user).from_channel(TestRunsChannel).once
        end

        it 'should not broadcast a message to other users' do
          expect { subject }
            .to have_broadcasted_to(user2.user).from_channel(TestRunsChannel).exactly 0
        end
      end

      context 'there is more than one group' do
        it 'should create a batch' do
          expect { subject }.to change { TestBatch.count }.from(0).to(1)
        end

        context 'there are more groups than the max_batch_size' do
          before { allow(Settings.autotest).to receive(:max_batch_size).and_return(2) }

          let(:n_groups) { 7 }

          it 'should call run_tests frice' do
            expect_any_instance_of(AutotestRunJob).to receive(:run_tests).exactly(4).times
            subject
          end
        end

        it 'should create a test run with a batch' do
          subject
          expect(TestRun.where(batch_id: TestBatch.first.id)).not_to be_nil
        end

        it 'should create a test run for each group' do
          subject
          expect(TestRun.where(grouping_id: groupings.map(&:id)).count).to eq n_groups
        end

        it 'should create test runs with in_progress status' do
          subject
          expect(TestRun.where(status: :in_progress).count).to eq n_groups
        end

        it 'should create test runs associated to the correct autotest_run_ids' do
          subject
          autotest_test_ids = TestRun.joins(grouping: :group).pluck('test_runs.autotest_test_id')
          expected = JSON.parse(dummy_return.body)['test_ids']
          expect(autotest_test_ids).to match_array(expected)
        end

        it 'should broadcast a message to the user' do
          expect { subject }
            .to have_broadcasted_to(role.user).from_channel(TestRunsChannel)
                                              .with(status: 'completed', job_class: 'AutotestRunJob')
        end
      end

      it 'should enqueue an AutotestResultsJob job' do
        expect(AutotestResultsJob).to receive(:perform_later).once
        subject
      end

      it 'should send an api request to the autotester' do
        expect_any_instance_of(AutotestRunJob).to receive(:send_request!) do |_j, net_obj, uri|
          expect(net_obj.instance_of?(Net::HTTP::Put)).to be true
          expect(uri.to_s).to eq "#{assignment.course.autotest_setting.url}/settings/10/test"
          dummy_return
        end
        subject
      end

      it_behaves_like 'autotest jobs'

      context 'where there is a starter file associated with the group' do
        let(:starter_file_group) { create(:starter_file_group, assignment: assignment) }
        let(:starter_file_entries) { create_list(:starter_file_entry, 3, starter_file_group: starter_file_group) }

        before do
          groupings.each do |g|
            starter_file_entries.each { |s| create(:grouping_starter_file_entry, grouping: g, starter_file_entry: s) }
          end
        end

        it 'should send the correct data' do
          expect_any_instance_of(AutotestRunJob).to receive(:send_request!) do |_j, net_obj|
            expect(JSON.parse(net_obj.body)['test_data']).to match_array(test_data)
            dummy_return
          end
          subject
        end
      end

      context 'when collected is true' do
        it 'should send the correct data' do
          expect_any_instance_of(AutotestRunJob).to receive(:send_request!) do |_j, net_obj|
            expect(JSON.parse(net_obj.body)['test_data']).to match_array(test_data)
            dummy_return
          end
          subject
        end

        it 'should create a test run associated to each submission' do
          subject
          expect(TestRun.where(submission: groupings.map(&:current_submission_used)).count).to eq n_groups
        end

        it 'should create runs with no revision id' do
          subject
          expect(TestRun.where(revision_identifier: nil).count).to eq n_groups
        end
      end

      context 'when collected is false' do
        let(:collected) { false }

        it 'should send the correct data' do
          expect_any_instance_of(AutotestRunJob).to receive(:send_request!) do |_j, net_obj|
            expect(JSON.parse(net_obj.body)['test_data']).to match_array(test_data)
            dummy_return
          end
          subject
        end

        it 'should create test runs with the lastet revision id' do
          revisions = groupings.map { |g| g.access_repo { |repo| repo.get_latest_revision.revision_identifier } }
          subject
          expect(TestRun.where(revision_identifier: revisions).count).to eq n_groups
        end

        it 'should create runs with no associated submission' do
          subject
          expect(TestRun.where(submission_id: nil).count).to eq n_groups
        end
      end

      context 'when the user is a student' do
        let(:role) { create(:student) }

        it 'should set the correct categories' do
          expect_any_instance_of(AutotestRunJob).to receive(:send_request!) do |_j, net_obj|
            expect(JSON.parse(net_obj.body)['categories'].uniq).to contain_exactly('student')
            dummy_return
          end
          subject
        end

        context 'when there is a single group' do
          let(:n_groups) { 1 }

          it 'should set high priority' do
            expect_any_instance_of(AutotestRunJob).to receive(:send_request!) do |_j, net_obj|
              expect(JSON.parse(net_obj.body)['request_high_priority']).to be true
              dummy_return
            end
            subject
          end
        end
      end

      context 'when the user is an instructor' do
        it 'should set the correct categories' do
          expect_any_instance_of(AutotestRunJob).to receive(:send_request!) do |_j, net_obj|
            expect(JSON.parse(net_obj.body)['categories'].uniq).to contain_exactly('instructor')
            dummy_return
          end
          subject
        end

        context 'when there is a single group' do
          let(:n_groups) { 1 }

          it 'should not set high priority' do
            expect_any_instance_of(AutotestRunJob).to receive(:send_request!) do |_j, net_obj|
              expect(JSON.parse(net_obj.body)['request_high_priority']).to be false
              dummy_return
            end
            subject
          end
        end
      end

      context 'when the user is a ta' do
        let(:role) { create(:ta) }

        it 'should set the correct categories' do
          expect_any_instance_of(AutotestRunJob).to receive(:send_request!) do |_j, net_obj|
            expect(JSON.parse(net_obj.body)['categories'].uniq).to contain_exactly('instructor')
            dummy_return
          end
          subject
        end

        context 'when there is a single group' do
          let(:n_groups) { 1 }

          it 'should not set high priority' do
            expect_any_instance_of(AutotestRunJob).to receive(:send_request!) do |_j, net_obj|
              expect(JSON.parse(net_obj.body)['request_high_priority']).to be false
              dummy_return
            end
            subject
          end
        end
      end
    end

    context 'tests are not set up' do
      it 'should raise an error' do
        expect { subject }.to raise_error(I18n.t('automated_tests.settings_not_setup'))
      end
    end

    context 'test environment is still being set up' do
      let(:assignment) { create(:assignment, assignment_properties_attributes: { remote_autotest_settings_id: 10 }) }

      it 'should broadcast a message to the user' do
        uri = URI("#{assignment.course.autotest_setting.url}/settings/#{assignment.remote_autotest_settings_id}/test")
        req = Net::HTTP::Put.new(uri)
        msg = 'Setting up test environment. Please try again later.'
        stub_request(:put, req.uri).to_return(status: 503,
                                              body: { 'message' => msg }.to_json)
        expect { subject }
          .to have_broadcasted_to(role.user).from_channel(TestRunsChannel)
                                            .with(a_hash_including(status: 'service_unavailable',
                                                                   exception: a_hash_including(message: msg),
                                                                   job_class: 'AutotestRunJob'))
      end
    end
  end
end
