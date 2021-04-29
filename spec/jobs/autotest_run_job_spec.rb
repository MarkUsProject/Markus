describe AutotestRunJob do
  let(:host_with_port) { 'http://localhost:3000' }
  let(:assignment) { create(:assignment) }
  let(:n_groups) { 3 }
  let(:groupings) { create_list(:grouping_with_inviter_and_submission, n_groups, assignment: assignment) }
  let(:groups) { groupings.map(&:group) }
  let(:user) { create(:admin) }
  context 'when running as a background job' do
    let(:job_args) { [host_with_port, user.id, assignment.id, groups.map(&:id)] }
    include_examples 'background job'
  end
  describe '#perform' do
    subject { described_class.perform_now(host_with_port, user.id, assignment.id, groups.map(&:id)) }
    context 'tests are set up for an assignment' do
      let(:assignment) { create :assignment, assignment_properties_attributes: { autotest_settings_id: 10 } }
      before do
        allow_any_instance_of(AutotestRunJob).to receive(:send_request!).and_return(
          OpenStruct.new(body: { 'test_ids' => (1..n_groups).to_a }.to_json)
        )
      end
      it 'should create a batch if there are more than one groups' do
        expect { subject }.to change { TestBatch.count }.from(0).to(1)
      end
    end
    context 'tests are not set up' do
      it 'should raise an error' do
        expect { subject }.to raise_error(I18n.t('automated_tests.settings_not_setup'))
      end
    end
  end
end
