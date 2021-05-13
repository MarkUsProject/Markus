describe AutotestCancelJob do
  let(:assignment) { create(:assignment) }
  let(:grouping) { create(:grouping, assignment: assignment) }
  let(:test_runs) { create_list(:test_run, 3, grouping: grouping, status: :in_progress) }
  let(:test_run_ids) { test_runs.map(&:id) }
  before { allow(File).to receive(:read).and_return("123456789\n") }
  context 'when running as a background job' do
    let(:job_args) { [assignment.id, test_run_ids] }
    include_examples 'background job'
  end
  describe '#perform' do
    subject { described_class.perform_now(assignment.id, test_run_ids) }
    context 'tests are set up for an assignment' do
      let(:assignment) { create :assignment, assignment_properties_attributes: { autotest_settings_id: 10 } }
      before { test_runs.each_with_index { |t, i| t.update!(autotest_test_id: i + 1) } }
      it 'should send an api request to the autotester' do
        expect_any_instance_of(AutotestCancelJob).to receive(:send_request!) do |_job, net_obj, uri|
          expect(net_obj.instance_of?(Net::HTTP::Delete)).to be true
          expect(uri.to_s).to eq "#{Settings.autotest.url}/settings/10/tests/cancel"
          expect(JSON.parse(net_obj.body)['test_ids']).to contain_exactly(1, 2, 3)
        end
        subject
      end
      it 'should set headers' do
        expect_any_instance_of(AutotestCancelJob).to receive(:send_request!) do |_job, net_obj|
          expect(net_obj['Api-Key']).to eq '123456789'
          expect(net_obj['Content-Type']).to eq 'application/json'
        end
        subject
      end
      it 'should cancel test runs' do
        allow_any_instance_of(AutotestCancelJob).to receive(:send_request!)
        subject
        expect(test_runs.map { |t| t.reload.status }.uniq).to contain_exactly('cancelled')
      end
      include_examples 'autotest jobs'
    end
    context 'tests are not set up' do
      it 'should raise an error' do
        expect { subject }.to raise_error(I18n.t('automated_tests.settings_not_setup'))
      end
    end
  end
end
