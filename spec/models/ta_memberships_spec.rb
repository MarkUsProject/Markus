describe TaMembership do
  it 'should belong to a ta' do
    expect(create(:ta_membership, user: create(:ta))).to be_valid
  end
  it 'should not belong to an admin' do
    expect { create :ta_membership, user: create(:admin) }.to raise_error(ActiveRecord::RecordInvalid)
  end
  it 'should not belong to an student' do
    expect { create :ta_membership, user: create(:student) }.to raise_error(ActiveRecord::RecordInvalid)
  end

  context 'should update permissions' do
    it 'when created' do
      expect(Repository.get_class).to receive(:__update_permissions)
      create(:ta_membership)
    end
    it 'when destroyed' do
      membership = create(:ta_membership)
      expect(Repository.get_class).to receive(:__update_permissions)
      membership.destroy
    end
  end
end
