describe GraderPermission do
  context 'checks relationships' do
    it { is_expected.to belong_to(:ta) }
  end
  context 'validates the presence of user id' do
    it { is_expected.to validate_presence_of(:user_id) }
  end
  describe 'Validating the user' do
    context 'When the user is admin' do
      let(:user) { create(:admin) }
      it 'should raise an invalid record error' do
        expect { create :grader_permission, user_id: user.id }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
    context 'When the user is grader' do
      let(:user) { create(:ta) }
      it 'should not raise an error' do
        expect(create(:grader_permission, user_id: user.id)).to be_valid
      end
    end
    context 'When the user is student' do
      let(:user) { create(:student) }
      it 'should raise an invalid record error' do
        expect { create :grader_permission, user_id: user.id }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end
end
