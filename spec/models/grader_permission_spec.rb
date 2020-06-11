describe GraderPermission do
  context 'checks relationships' do
    it { is_expected.to belong_to(:user) }
  end
  context 'validates the presence of user id' do
    it { is_expected.to validate_presence_of(:user_id) }
  end
end
