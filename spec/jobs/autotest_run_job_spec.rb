describe AutotestRunJob do
  let(:host_with_port) { 'http://localhost:3000' }
  let(:assignment) { create(:assignment) }
  let(:n_groups) { 3 }
  let(:groupings) { create_list(:grouping_with_inviter_and_submission, n_groups, assignment: assignment) }
  let(:groups) { groupings.map(&:group) }
  let(:user) { create(:admin) }
  before { allow(File).to receive(:read).and_return("123456789\n") }
  context 'when running as a background job' do
    let(:job_args) { [host_with_port, user.id, assignment.id, groups.map(&:id)] }
    before { allow(AutotestResultsJob).to receive(:set) }
    include_examples 'background job'
  end
  describe '#perform' do
    after do
      clear_enqueued_jobs
      clear_performed_jobs
    end
    let(:collected) { true }
    subject do
      described_class.perform_now(host_with_port, user.id, assignment.id, groups.map(&:id), collected: collected)
    end
    context 'tests are set up for an assignment' do
      let(:assignment) { create :assignment, assignment_properties_attributes: { autotest_settings_id: 10 } }
      let(:dummy_return) { OpenStruct.new(body: { 'test_ids' => (1..n_groups).to_a }.to_json) }
      before do
        allow_any_instance_of(AutotestRunJob).to receive(:send_request!).and_return(dummy_return)
      end
      context 'if there is only one group' do
        let(:n_groups) { 1 }
        it 'should not create a batch' do
          expect { subject }.not_to(change { TestBatch.count })
        end
        it 'should create a test run without an associated batch' do
          subject
          expect(TestRun.where(batch_id: nil)).not_to be_nil
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
      end
      it 'should enqueue an AutotestResultsJob job' do
        expect(AutotestResultsJob).to receive(:perform_later).once
        subject
      end
      it 'should send an api request to the autotester' do
        expect_any_instance_of(AutotestRunJob).to receive(:send_request!) do |_j, net_obj, uri|
          expect(net_obj.instance_of?(Net::HTTP::Put)).to be true
          expect(uri.to_s).to eq "#{Settings.autotest.url}/settings/10/test"
          dummy_return
        end
        subject
      end
      include_examples 'autotest jobs'
      context 'when collected is true' do
        it 'should send the correct url' do
          file_urls = groups.map do |group|
            "http://localhost:3000#{Rails.configuration.action_controller.relative_url_root}" \
            "/api/assignments/#{assignment.id}/groups/#{group.id}/submission_files?collected=true"
          end
          expect_any_instance_of(AutotestRunJob).to receive(:send_request!) do |_j, net_obj|
            expect(JSON.parse(net_obj.body)['file_urls']).to contain_exactly(*file_urls)
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
        it 'should send the correct url' do
          url_root = Rails.configuration.action_controller.relative_url_root
          file_urls = groups.map do |group|
            "http://localhost:3000#{url_root}/api/assignments/#{assignment.id}/groups/#{group.id}/submission_files?"
          end
          expect_any_instance_of(AutotestRunJob).to receive(:send_request!) do |_j, net_obj|
            expect(JSON.parse(net_obj.body)['file_urls']).to contain_exactly(*file_urls)
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
        let(:user) { create(:student) }
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
              expect(JSON.parse(net_obj.body)['request_high_priority']).to eq true
              dummy_return
            end
            subject
          end
        end
      end
      context 'when the user is an admin' do
        it 'should set the correct categories' do
          expect_any_instance_of(AutotestRunJob).to receive(:send_request!) do |_j, net_obj|
            expect(JSON.parse(net_obj.body)['categories'].uniq).to contain_exactly('admin')
            dummy_return
          end
          subject
        end
        context 'when there is a single group' do
          let(:n_groups) { 1 }
          it 'should not set high priority' do
            expect_any_instance_of(AutotestRunJob).to receive(:send_request!) do |_j, net_obj|
              expect(JSON.parse(net_obj.body)['request_high_priority']).to eq false
              dummy_return
            end
            subject
          end
        end
      end
      context 'when the user is a ta' do
        let(:user) { create(:ta) }
        it 'should set the correct categories' do
          expect_any_instance_of(AutotestRunJob).to receive(:send_request!) do |_j, net_obj|
            expect(JSON.parse(net_obj.body)['categories'].uniq).to contain_exactly('admin')
            dummy_return
          end
          subject
        end
        context 'when there is a single group' do
          let(:n_groups) { 1 }
          it 'should not set high priority' do
            expect_any_instance_of(AutotestRunJob).to receive(:send_request!) do |_j, net_obj|
              expect(JSON.parse(net_obj.body)['request_high_priority']).to eq false
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
  end
end
