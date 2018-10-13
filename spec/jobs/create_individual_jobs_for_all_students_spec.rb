describe CreateIndividualGroupsForAllStudentsJob do
  let(:assignment) { create :assignment }
  it 'should attempt to update permissions file' do
    expect(Repository.get_class).to receive(:update_permissions_after)
    CreateIndividualGroupsForAllStudentsJob.perform_now(assignment)
  end
end
