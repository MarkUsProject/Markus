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

  describe '.from_csv' do
    let(:assignment) { create(:assignment) }
    let(:ta) { create(:ta, course: assignment.course) }
    let(:grouping) { create(:grouping, assignment: assignment) }

    it 'does not create duplicate memberships when same grader-group pair exists' do
      create(:ta_membership, role: ta, grouping: grouping)
      csv_data = "#{grouping.group.group_name},#{ta.user.user_name}"

      expect { TaMembership.from_csv(assignment, csv_data, false) }
        .not_to(change { TaMembership.count })
    end

    it 'handles duplicate entries within the same CSV' do
      csv_data = "#{grouping.group.group_name},#{ta.user.user_name}\n#{grouping.group.group_name},#{ta.user.user_name}"

      expect { TaMembership.from_csv(assignment, csv_data, false) }
        .to change { TaMembership.count }.by(1)
    end
  end
end
