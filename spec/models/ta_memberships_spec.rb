describe TaMembership do
  subject { create(:ta_membership) }

  it { is_expected.to have_one(:course) }

  it_behaves_like 'course associations'
  it 'should belong to a ta' do
    expect(create(:ta_membership, role: create(:ta))).to be_valid
  end

  it 'should not belong to an instructor' do
    expect { create(:ta_membership, role: create(:instructor)) }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it 'should not belong to an student' do
    expect { create(:ta_membership, role: create(:student)) }.to raise_error(ActiveRecord::RecordInvalid)
  end

  context 'should update permissions' do
    it 'when created' do
      grouping = create(:grouping)
      expect(UpdateRepoPermissionsJob).to receive(:perform_later)
      create(:ta_membership, grouping: grouping)
    end

    it 'when destroyed' do
      membership = create(:ta_membership)
      expect(UpdateRepoPermissionsJob).to receive(:perform_later)
      membership.destroy
    end
  end
end
