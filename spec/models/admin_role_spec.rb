describe AdminRole do
  subject { create(:admin_role) }

  it { is_expected.to validate_uniqueness_of(:user_id).scoped_to(:course_id) }

  describe 'An admin role' do
    it 'cannot be assigned to an end user' do
      expect(build(:admin_role, user: create(:end_user))).not_to be_valid
    end

    it 'cannot be assigned to an autotest user' do
      expect(build(:admin_role, user: create(:autotest_user))).not_to be_valid
    end
  end
end
