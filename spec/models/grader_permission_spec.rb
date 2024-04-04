describe GraderPermission do
  context 'checks relationships' do
    it { is_expected.to belong_to(:ta) }
    it { is_expected.to have_one(:course) }
  end
  describe 'Validating the user' do
    context 'When the user is instructor' do
      let(:user) { create(:instructor) }
      it 'should raise an invalid record error' do
        expect { create(:grader_permission, role_id: user.id) }.to raise_error(ActiveRecord::RecordInvalid)
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
        expect { create(:grader_permission, role_id: user.id) }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end
end
