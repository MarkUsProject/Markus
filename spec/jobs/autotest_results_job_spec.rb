describe AutotestResultsJob do
  let(:assignment) { create :assignment }
  let(:grouping) { create(:grouping, assignment: assignment) }
  let(:test_runs) { create_list(:test_run, 3, grouping: grouping, status: :in_progress) }

  context 'when running as a background job' do
    let(:job_args) { [assignment.id] }
    let(:job) { described_class.perform_later(*job_args) }
    context 'if there is no job currently in progress' do
      before { redis.del('autotest_results') }
      include_examples 'background job'
      it 'sets the redis key' do
        job
        expect(redis.get('autotest_results')).not_to be_nil
      end
    end
    context 'if there is a job currently in progress' do
      before do
        redis.set('autotest_results', 1)
        clear_enqueued_jobs
        clear_performed_jobs
      end
      after do
        clear_enqueued_jobs
        clear_performed_jobs
        redis.del('autotest_results')
      end

      it 'does not enqueue a job' do
        expect { job }.not_to have_enqueued_job
      end
    end
  end
  describe '#perform' do
    before do
      redis.del('autotest_results')
      allow_any_instance_of(AutotestSetting).to(
        receive(:send_request!).and_return(OpenStruct.new(body: { api_key: 'someapikey' }.to_json))
      )
      course = create(:course)
      course.autotest_setting = create(:autotest_setting)
      course.save
      test_runs.each_with_index { |t, i| t.update!(autotest_test_id: i + 1) }
    end
    subject { described_class.perform_now }
    context 'tests are set up for an assignment' do
      let(:assignment) { create :assignment, assignment_properties_attributes: { remote_autotest_settings_id: 10 } }
      let(:dummy_return) { Net::HTTPSuccess.new(1.0, '200', 'OK') }
      let(:body) { '{}' }
      before { allow(dummy_return).to receive(:body) { body } }
      context 'when getting the statuses of the tests' do
        it 'should set headers' do
          expect_any_instance_of(AutotestResultsJob).to receive(:send_request!) do |_job, net_obj|
            expect(net_obj['Api-Key']).to eq assignment.course.autotest_setting.api_key
            expect(net_obj['Content-Type']).to eq 'application/json'
            dummy_return
          end
          subject
        end
        it 'should send an api request to the autotester' do
          expect_any_instance_of(AutotestResultsJob).to receive(:send_request!) do |_job, net_obj, uri|
            expect(net_obj.instance_of?(Net::HTTP::Get)).to be true
            expect(uri.to_s).to eq "#{assignment.course.autotest_setting.url}/settings/10/tests/status"
            expect(JSON.parse(net_obj.body)['test_ids']).to contain_exactly(1, 2, 3)
            dummy_return
          end
          subject
        end
        include_examples 'autotest jobs'
      end
      context 'after getting the statuses of the tests' do
        before { allow_any_instance_of(AutotestResultsJob).to receive(:statuses).and_return(status_return) }

        shared_examples 'rescheduling a job' do
          before { allow_any_instance_of(AutotestResultsJob).to receive(:results) }
          it 'should schedule another job in a minute' do
            expect(AutotestResultsJob).to receive(:set).with(wait: 5.seconds).once.and_call_original
            expect_any_instance_of(ActiveJob::ConfiguredJob).to receive(:perform_later).once
            subject
          end
        end
        shared_examples 'getting results' do
          context 'a successful request' do
            it 'should set headers' do
              allow_any_instance_of(TestRun).to receive(:update_results!)
              expect_any_instance_of(AutotestResultsJob).to receive(:send_request) do |_job, net_obj|
                expect(net_obj['Api-Key']).to eq assignment.course.autotest_setting.api_key
                expect(net_obj['Content-Type']).to eq 'application/json'
                dummy_return
              end
              subject
            end
            it 'should send an api request to the autotester' do
              allow_any_instance_of(TestRun).to receive(:update_results!)
              expect_any_instance_of(AutotestResultsJob).to receive(:send_request) do |_job, net_obj, uri|
                expect(net_obj.instance_of?(Net::HTTP::Get)).to be true
                expect(uri.to_s).to eq "#{assignment.course.autotest_setting.url}/settings/10/test/2"
                dummy_return
              end
              subject
            end
            it 'should call update_results! for the test_run' do
              allow_any_instance_of(AutotestResultsJob).to receive(:send_request).and_return(dummy_return)
              expect_any_instance_of(TestRun).to receive(:update_results!).with({}) do |test_run|
                expect(test_run.autotest_test_id).to eq 2
              end
              subject
            end
          end
          context 'an unsuccessful request' do
            let(:dummy_return) { Net::HTTPServerError.new(1.0, '500', 'Server Error') }
            before do
              allow_any_instance_of(AutotestResultsJob).to receive(:send_request).and_return(dummy_return)
            end
            it 'should call failure for the test_run' do
              expect_any_instance_of(TestRun).to receive(:failure).with('{}') do |test_run|
                expect(test_run.autotest_test_id).to eq 2
              end
              subject
            end
          end
        end
        context 'when at least one of the statuses is "started"' do
          let(:status_return) { { 1 => 'finished', 2 => 'started', 3 => 'finished' } }
          include_examples 'rescheduling a job'
        end
        context 'when at least one of the statuses is "queued"' do
          let(:status_return) { { 1 => 'finished', 2 => 'queued', 3 => 'finished' } }
          include_examples 'rescheduling a job'
        end
        context 'when at least one of the statuses is "deferred"' do
          let(:status_return) { { 1 => 'finished', 2 => 'deferred', 3 => 'finished' } }
          include_examples 'rescheduling a job'
        end
        context 'when at least one of the statuses is "finished"' do
          let(:status_return) { { 1 => 'started', 2 => 'finished', 3 => 'started' } }
          include_examples 'getting results'
        end
        context 'when at least one of the statuses is "failed"' do
          let(:status_return) { { 1 => 'started', 2 => 'failed', 3 => 'started' } }
          include_examples 'getting results'
        end
        context 'when at least one of the statuses is something else' do
          let(:status_return) { { 1 => 'started', 2 => 'something else', 3 => 'started' } }
          it 'should call failure for the test_run' do
            expect_any_instance_of(TestRun).to receive(:failure).with('something else') do |test_run|
              expect(test_run.autotest_test_id).to eq 2
            end
            subject
          end
        end
      end
    end
    context 'tests are not set up' do
      it 'should try again with reduced retries' do
        expect { subject }.to raise_error(I18n.t('automated_tests.settings_not_setup'))
      end
    end
  end
end
