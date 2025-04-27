describe AutotestCancelJob do
  let(:assignment) { create(:assignment) }
  let(:grouping) { create(:grouping, assignment: assignment) }
  let(:test_runs) { create_list(:test_run, 3, grouping: grouping, status: :in_progress) }
  let(:test_run_ids) { test_runs.map(&:id) }

  before do
    allow_any_instance_of(AutotestSetting).to(
      receive(:send_request!).and_return(OpenStruct.new(body: { api_key: 'someapikey' }.to_json))
    )
    course = create(:course)
    course.autotest_setting = create(:autotest_setting)
    course.save
  end

  context 'when running as a background job' do
    let(:job_args) { [assignment.id, test_run_ids] }

    it_behaves_like 'background job'
  end

  describe '#perform' do
    subject { AutotestCancelJob.perform_now(assignment.id, test_run_ids) }

    context 'tests are set up for an assignment' do
      let(:assignment) { create(:assignment, assignment_properties_attributes: { remote_autotest_settings_id: 10 }) }

      it 'should send an api request to the autotester' do
        expect_any_instance_of(AutotestCancelJob).to receive(:send_request!) do |_job, net_obj, uri|
          expect(net_obj.instance_of?(Net::HTTP::Delete)).to be true
          expect(uri.to_s).to eq "#{assignment.course.autotest_setting.url}/settings/10/tests/cancel"
        end
        subject
      end

      context 'when all test runs are cancelable' do
        before { test_runs.each_with_index { |t, i| t.update!(autotest_test_id: i + 1) } }

        it 'should request to cancel all test runs' do
          expect_any_instance_of(AutotestCancelJob).to receive(:send_request!) do |_job, net_obj, uri|
            expect(net_obj.instance_of?(Net::HTTP::Delete)).to be true
            expect(uri.to_s).to eq "#{assignment.course.autotest_setting.url}/settings/10/tests/cancel"
            expect(JSON.parse(net_obj.body)['test_ids']).to contain_exactly(1, 2, 3)
          end
          subject
        end
      end

      context 'when only some of the test runs are cancelable' do
        before { test_runs[0...2].each_with_index { |t, i| t.update!(autotest_test_id: i + 1) } }

        it 'should only request to cancel test runs with autotest_test_id values' do
          expect_any_instance_of(AutotestCancelJob).to receive(:send_request!) do |_job, net_obj, _uri|
            expect(JSON.parse(net_obj.body)['test_ids']).to contain_exactly(1, 2)
          end
          subject
        end
      end

      it 'should set headers' do
        expect_any_instance_of(AutotestCancelJob).to receive(:send_request!) do |_job, net_obj|
          expect(net_obj['Api-Key']).to eq assignment.course.autotest_setting.api_key
          expect(net_obj['Content-Type']).to eq 'application/json'
        end
        subject
      end

      it 'should cancel test runs' do
        allow_any_instance_of(AutotestCancelJob).to receive(:send_request!)
        subject
        expect(test_runs.map { |t| t.reload.status }.uniq).to contain_exactly('cancelled')
      end

      it_behaves_like 'autotest jobs'
    end

    context 'tests are not set up' do
      it 'should raise an error' do
        expect { subject }.to raise_error(I18n.t('automated_tests.settings_not_setup'))
      end
    end
  end
end
