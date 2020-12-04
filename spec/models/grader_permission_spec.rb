describe GraderPermission do
  context 'checks relationships' do
    it { is_expected.to belong_to(:ta) }
  end
  describe 'Validating the user' do
    context 'When the user is admin' do
      let(:user) { create(:admin) }
      it 'should raise an invalid record error' do
        expect { create :grader_permission, user_id: user.id }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
    # Creating a TA will automatically create associated grader_permission
    context 'When the user is grader' do
      it 'should not raise an error' do
        expect(create(:ta)).to be_valid
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
