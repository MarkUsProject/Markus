describe AutomatedTestsController do
  let(:assignment) { create :assignment }
  let(:admin) { create :admin }
  context 'GET download_files' do
    subject { get_as admin, :download_files, params: { assignment_id: assignment.id } }
    let(:content) { response.body }
    it_behaves_like 'zip file download'

    it 'should be successful' do
      subject
      expect(response.status).to eq(200)
    end
  end
end
