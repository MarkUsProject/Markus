describe TestStudent do
  context 'A Test Student model' do
    it 'will have many accepted groupings' do
      is_expected.to have_many(:accepted_groupings).through(:memberships)
    end

    it 'will have many student memberships' do
      is_expected.to have_many :student_memberships
    end
  end

  describe '#validate_membership_status' do
    let(:test_student) { create(:test_student) }
    let(:assignment) { create(:assignment) }
    context 'When test student is the inviter of his grouping' do
      let!(:grouping) { create(:grouping_with_inviter, assignment: assignment, inviter: test_student) }
      it 'should return true' do
        expect(test_student.validate_membership_status).to be true
      end
    end
    context 'When test student is not the inviter of his grouping' do
      let(:grouping) { create(:grouping_with_inviter, assignment: assignment) }
      let!(:membership) { create(:membership, user: test_student, grouping: grouping) }
      it 'should return false' do
        expect(test_student.validate_membership_status).to be false
      end
    end
  end

  describe '#validate_grouping_member' do
    let(:test_student) { create(:test_student) }
    let(:assignment) { create(:assignment) }
    context 'When test student is the only member in his grouping' do
      let!(:grouping) { create(:grouping_with_inviter, assignment: assignment, inviter: test_student) }
      it 'should return true' do
        expect(test_student.validate_grouping_member(grouping)).to be true
        expect(grouping.memberships.count).to eq(1)
      end
    end
    context 'When test student grouping has more than one member' do
      let(:grouping) { create(:grouping_with_inviter, assignment: assignment, inviter: test_student) }
      let(:student) { create(:student) }
      let!(:membership) { create(:membership, user: student, grouping: grouping) }
      it 'should return false' do
        expect(test_student.validate_grouping_member(grouping)).to be false
        expect(grouping.memberships.count).to eq(2)
      end
    end
  end
end
